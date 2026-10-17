package.path = 'src/?.lua;' .. package.path
local now, sequence, saves, requests, responses, batches = 100000000, 0, 0, {}, {}, {}
local function raise(e) error(e, 0) end
local qcm = {
    inner = {}, time = {now = function() return now end},
    error = raise, errors = {inspect = function(e) return type(e) == 'table' and e or nil end},
}
function qcm.inner:new_session_id() sequence = sequence + 1; return 'scope-' .. sequence end
function qcm.inner:begin_session() end
function qcm.inner:save_session() saves = saves + 1; return 'saved' end
function qcm.inner:session_task(_, f) return f() end
local function builder(url)
    local b = {url = url}
    for _, name in ipairs {'headers', 'query', 'timeout', 'form'} do b[name] = function(self, value) self[name .. '_value'] = value; return self end end
    function b:build() return self end
    function b:send()
        requests[#requests + 1] = self
        local r = assert(table.remove(responses, 1), 'unexpected request ' .. self.url)
        if r.failure then raise(r.failure) end
        return r
    end
    return b
end
local http = {}
function http:get(url) return builder(url) end
function http:post(url) return builder(url) end
function http:new_batch()
    local b = {pending = {}}
    function b:add(key, request) self.pending[#self.pending + 1] = {key = key, response = request:send()} end
    function b:seal() self.sealed = true end
    function b:wait_one() return table.remove(self.pending, 1) end
    function b:close() self.closed = true end
    batches[#batches + 1] = b
    return b
end
function qcm.get_http_client() return http end
package.preload['qcm.mod'] = function() return qcm end
package.preload.json = function() return {encode = function() return '{}' end} end
package.preload.crypto = function() return {weapi = function() return {} end, eapi = function() return {} end} end
local Session, Client = require('session'), require('client')
local function response(body, token, url, broken)
    local reads = 0
    return {
        close = function() end,
        url = function() return url or 'https://music.163.com/weapi/test' end,
        header_values = function(_, name) assert(name == 'x-refresh-token'); return token and {token} or {} end,
        json = function() reads = reads + 1; assert(reads == 1, 'body consumed twice'); if broken then raise('invalid JSON') end; return body end,
    }
end
local function api(retry)
    return {
        retry_after_auth = retry,
        path = function() return '/test' end, crypto = function() return 'weapi' end,
        operation = function() return 'POST' end, query = function() return {} end,
        body = function() return {} end, parse_response = function(_, r) return r:json() end,
    }
end
local function fresh(state)
    requests, responses, batches, saves = {}, {}, {}, 0
    local s = Session.new(); s:load(state, true)
    return s, Client.new('test', s)
end
local passed = 0
local function test(name, f)
    f(); passed = passed + 1; print('ok ' .. name)
end
local function fails(f, code)
    local ok, err = pcall(f); assert(not ok, 'expected failure')
    if code then assert(type(err) == 'table' and err.code == code, tostring(err)) end
    return err
end

test('old state and stable resource scope', function()
    local s = fresh(); local scope = s:scope(); assert(scope == s:scope())
    s.state.refresh_token = 'a';s.state.refresh_time = now;assert(s:scope() == scope)
    local loaded = Session.new();loaded:load(s.state);assert(loaded:scope() == scope)
    s:authenticated();assert(s:scope() ~= scope)
    fails(function() s:load {refresh_token = 1} end)
    fails(function() s:load {refresh_time = -1} end)
end)
test('capture token before a broken body and save', function()
    local s,c = fresh(); responses = {response(nil, 'synthetic', nil, true)}
    fails(function() c:perform(api(), 30) end)
    assert(s.state.refresh_token == 'synthetic' and saves == 1)
end)
test('empty and missing headers preserve token', function()
    local s,c = fresh {refresh_token = 'existing', refresh_time = now}
    responses = {response({code = 200}, ''), response({code = 200})}
    c:perform(api(),30);c:perform(api(),30);assert(s.state.refresh_token == 'existing' and saves == 2)
end)
test('foreign response cannot inject token', function()
    local s,c = fresh(); responses = {response({code = 200}, 'foreign', 'https://cdn.invalid/test')}
    c:perform(api(),30);assert(s.state.refresh_token == nil)
end)
test('business failure still saves received token', function()
    local s,c = fresh();responses = {response({code = 500}, 'synthetic')}
    fails(function() c:perform(api(),30) end);assert(s.state.refresh_token == 'synthetic' and saves == 1)
end)
test('successful refresh and latest response token', function()
    local s,c = fresh {refresh_token = 'before'}
    responses = {response({code = 200}, 'after'),response({code = 200})}
    local scope=s:scope();c:perform(api(),30)
    assert(requests[1].url:match('/eapi/login/token/refresh$') and #requests == 2)
    assert(s.state.refresh_time == now and s.state.refresh_token == 'after' and s:scope() == scope)
end)
test('refresh interval and clock rollback', function()
    local s,c = fresh {refresh_token = 'token', refresh_time = now}
    responses = {response({code = 200})}; c:perform(api(),30);assert(#requests == 1)
    now = now - 1;responses = {response({code = 200}),response({code = 200})};c:perform(api(),30);assert(#requests == 3)
end)
test('network failure backs off without changing refresh time', function()
    local s,c = fresh {refresh_token = 'token'}
    responses = {{failure = {domain = 'http', code = 'transport'}},response({code = 200})}
    c:perform(api(),30);assert(s.state.refresh_time == nil and s.retry_at > now)
    responses = {response({code = 200})};c:perform(api(),30);assert(#requests == 3)
end)
test('storage failure is not hidden by refresh backoff', function()
    local s,c = fresh {refresh_token = 'token'}
    local save = qcm.inner.save_session
    qcm.inner.save_session = function() raise({code = 'storage_failure'}) end
    responses = {response({code = 200}, 'rotated')}
    fails(function() c:perform(api(),30) end, 'storage_failure')
    qcm.inner.save_session = save;assert(s.state.refresh_time == nil)
end)
test('query replays at most once after recovery', function()
    local s,c = fresh();responses = {response({code = 301}),response({code = 200,data = {action = 1}},'recovered'),response({code = 200})}
    c:perform(api(true),30);assert(#requests == 3 and s.state.refresh_token == 'recovered')
end)
test('write operation is not replayed', function()
    local s,c = fresh();responses = {response({code = 301}),response({code = 200,data = {action = 1}})}
    fails(function() c:perform(api(false),30) end,'not_auth');assert(#requests == 2)
end)
test('repeated unauthorized result stops after one replay', function()
    local s,c = fresh();responses = {response({code = 301}),response({code = 200,data = {action = 1}}),response({code = 301})}
    fails(function() c:perform(api(true),30) end,'not_auth');assert(#requests == 3)
end)
test('proactive refresh rejection recovers without recursive refresh', function()
    local s,c = fresh {refresh_token='token'}
    responses = {response({code=301}),response({code=200,data={action=1}}),response({code=200})}
    c:perform(api(true),30);assert(#requests==3)
end)
for _, action in ipairs {2,3,4} do
    test('recovery action ' .. action, function()
        local s,c = fresh();responses = {response({code=301}),response({code=200,data={action=action,message='login needed',jumpUrl='https://music.163.com/test'}})}
        local err=fails(function() c:perform(api(true),30) end,'not_auth')
        assert(#requests==2)
        if action==3 then assert(err.jump_url=='https://music.163.com/test') end
        responses={response({code=301})};fails(function() c:perform(api(true),30) end,'not_auth');assert(#requests==3)
    end)
end
test('recovery threshold terminates subsequent attempts', function()
    local s,c=fresh()
    for i=1,2 do
        responses={response({code=301}),response({code=500})}
        fails(function() c:perform(api(true),30) end,'not_auth');now=now+5001
    end
    responses={response({code=301})};fails(function() c:perform(api(true),30) end,'not_auth');assert(#requests==5)
end)
test('batch captures headers using the shared response path', function()
    local s,c=fresh();responses={response({code=200},'batch-token'),response({code=200})}
    local n=0;local rs=c:perform_queue(function() n=n+1;return n<=2 and api(true) or nil end,30)
    assert(#rs==2 and s.state.refresh_token=='batch-token' and saves==2 and batches[1].closed)
end)
test('batch closes after parsing or business failure', function()
    local s,c=fresh();responses={response(nil,'saved',nil,true)}
    local n=0;fails(function() c:perform_queue(function() n=n+1;return n==1 and api(true) or nil end,30) end)
    assert(s.state.refresh_token=='saved' and batches[1].closed)
end)
test('old account response cannot mutate new state', function()
    local s=fresh();local old=s.generation;s:begin()
    fails(function() s:accept(response({code=200},'old'),old) end,'not_auth')
    assert(s.state.refresh_token==nil)
end)
test('credentials are saved before body consumption and response is closed', function()
    local s,c=fresh();local closed=false
    responses={{url=function() return 'https://music.163.com/weapi/test' end,
        header_values=function() return {'token',''} end,
        json=function() assert(saves==1 and s.state.refresh_token=='token');raise('cancelled body') end,
        close=function() closed=true end}}
    fails(function() c:perform(api(true),30) end);assert(closed)
end)
test('anonymous sessions do not proactively refresh', function()
    local s,c=fresh {refresh_token='token'};s.has_account=false
    responses={response({code=200})};c:perform(api(),30);assert(#requests==1)
end)
test('batch performs due refresh before building API requests', function()
    local s,c=fresh {refresh_token='token'}
    responses={response({code=200},'new'),response({code=200})}
    local n=0;c:perform_queue(function() n=n+1;return n==1 and api(true) or nil end,30)
    assert(requests[1].url:match('/login/token/refresh$') and requests[2].url:match('/test$'))
    assert(s.state.refresh_token=='new' and batches[1].closed)
end)
test('batch recovery rebuilds only the failed safe query', function()
    local s,c=fresh()
    responses={response({code=301}),response({code=200}),response({code=200,data={action=1}}),response({code=200})}
    local n=0;local results=c:perform_queue(function() n=n+1;return n<=2 and api(true) or nil end,30)
    assert(#results==2 and #requests==4 and batches[1].closed)
end)
test('QR polling results bypass refresh and recovery', function()
    local s,c=fresh{refresh_token='token'}
    local poll=api();poll.auth_request=true;poll.no_error_check=true
    for _,code in ipairs{800,801,802,803} do
        responses={response({code=code})};assert(c:perform(poll,30).code==code)
    end
    assert(#requests==4 and s.state.refresh_time==nil)
end)
test('batch transport failure closes the batch', function()
    local s,c=fresh();responses={{failure={domain='http',code='transport'}}}
    local n=0;fails(function() c:perform_queue(function() n=n+1;return n==1 and api(true) or nil end,30) end)
    assert(batches[1].closed)
end)
test('refresh transport failures do not exhaust authentication recovery', function()
    local s,c=fresh {refresh_token='token'}
    for _=1,3 do
        responses={{failure={domain='http',code='transport'}},response({code=200})}
        c:perform(api(true),30);now=now+300001
    end
    responses={{failure={domain='http',code='transport'}},response({code=301}),response({code=200,data={action=1}}),response({code=200})}
    c:perform(api(true),30)
    assert(s.recovered and s.recovery_failures==0 and s.refresh_failures==4)
end)
print(passed .. ' session tests passed')
