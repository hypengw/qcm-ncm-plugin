local qcm = require('qcm.mod')
local Session = {}
Session.__index = Session
local INTERVAL = 86400000
local COOLDOWN = 5000
local invalid = require('error').is_not_auth
local function not_auth(message, jump_url)
    qcm.error {code = 'not_auth', message = message or 'Login required', jump_url = jump_url}
end
Session.invalid = invalid

function Session.new()
    return setmetatable({
        state = {resource_scope = qcm.inner:new_session_id()},
        generation = 0,
        revision = 0,
        refresh_failures = 0,
        recovery_failures = 0,
        retry_at = 0,
        force_at = 0,
        recovery_at = 0,
    }, Session)
end
function Session:load(state, has_account)
    if state == nil then state = {} end
    assert(type(state) == 'table', 'invalid saved NCM session')
    for _, key in ipairs {'refresh_token', 'resource_scope'} do
        assert(state[key] == nil or type(state[key]) == 'string', 'invalid saved NCM session')
    end
    local time = state.refresh_time
    assert(time == nil or (math.type(time) == 'integer' and time >= 0), 'invalid saved NCM refresh time')
    self.state = {
        refresh_token = state.refresh_token,
        refresh_time = time,
        resource_scope = state.resource_scope or qcm.inner:new_session_id(),
    }
    self.has_account = has_account == true
    self.generation = self.generation + 1
    self.revision = 0
    self.refresh_failures, self.recovery_failures = 0, 0
    self.retry_at, self.force_at, self.recovery_at, self.recovered = 0, 0, 0, false
end
function Session:begin()
    qcm.inner:begin_session()
    self:load({})
end
function Session:authenticated()
    self.has_account = true
    self.state.resource_scope = qcm.inner:new_session_id()
end
function Session:scope()
    return assert(self.state.resource_scope, 'missing NCM resource scope')
end
function Session:check(generation)
    if generation ~= self.generation then not_auth('Account changed during request') end
end
function Session:save()
    local generation = self.generation
    local result = qcm.inner:save_session()
    self:check(generation)
    return result
end
function Session:accept(response, generation)
    self:check(generation)
    local origin = response:url():match('^(https://[^/]+)')
    if origin ~= 'https://music.163.com' and origin ~= 'https://interface.music.163.com' then return end
    local tokens = response:header_values('x-refresh-token')
    for i = #tokens, 1, -1 do
        if tokens[i] ~= '' then self.state.refresh_token = tokens[i]; break end
    end
end
function Session:_task(kind, run)
    local generation = self.generation
    local result = qcm.inner:session_task('ncm.auth.' .. generation, function()
        self:check(generation)
        return {kind = kind, value = run()}
    end)
    self:check(generation)
    if result.kind ~= kind then return self:_task(kind, run) end
    return result.value
end
function Session:_refresh_due(force)
    if not self.has_account or not self.state.refresh_token or self.state.refresh_token == '' then return false end
    local now = qcm.time.now()
    if now < self.retry_at then return false end
    if force then return now >= self.force_at end
    local last = self.state.refresh_time
    return not last or now < last or now - last >= INTERVAL
end
function Session:refresh(client, force, revision)
    if revision and self.revision > revision then return true end
    if not force and not self:_refresh_due(false) then return end
    return self:_task('refresh', function()
        if revision and self.revision > revision then return true end
        if not self:_refresh_due(force) then return end
        local generation = self.generation
        self.force_at = qcm.time.now() + COOLDOWN
        local api = require('api.login.token.refresh').new(self.state.refresh_token)
        local ok, result = pcall(client._send, client, api, 30)
        self:check(generation)
        local code = ok and result.code or nil
        local account_code
        local unauthorized = ok and invalid(result.code)
        if ok and result.code == 200 then
            local account = require('api.nuser.account').new()
            ok, result = pcall(client._send, client, account, 30)
            self:check(generation)
            account_code = ok and result.code or nil
            if ok and result.code == 200 and not account:auth_invalid(result) then
                local state, previous = self.state, self.state.refresh_time
                state.refresh_time = qcm.time.now()
                local saved, failure = pcall(self.save, self)
                if not saved then
                    if self.state == state then state.refresh_time = previous end
                    error(failure, 0)
                end
                self.refresh_failures, self.retry_at = 0, 0
                self.revision = self.revision + 1
                qcm.debug {component = 'ncm.session', event = 'refresh_verified', forced = force == true}
                return true
            end
            unauthorized = ok and (invalid(result.code) or account:auth_invalid(result))
        end
        self:backoff()
        qcm.debug {component = 'ncm.session', event = 'refresh_failed', forced = force == true,
            code = code, account_code = account_code}
        if unauthorized then return false end
        if not ok then
            local info = qcm.errors.inspect(result)
            if not info or info.domain ~= 'http' or (info.code ~= 'transport' and info.code ~= 'timeout') then error(result, 0) end
        end
    end)
end
function Session:ensure(client)
    if self:refresh(client, false) == false then self:recover(client, '/login/token/refresh') end
end
function Session:backoff()
    self.refresh_failures = self.refresh_failures + 1
    self.retry_at = qcm.time.now() + math.min(300000, COOLDOWN * 2 ^ math.min(self.refresh_failures - 1, 6))
end
function Session:recover(client, path, revision)
    if revision and self:refresh(client, true, revision) then return end
    return self:_task('recover', function()
        if revision and self.revision > revision then return end
        if qcm.time.now() < self.recovery_at then
            if self.recovered then return end
            not_auth()
        end
        self.recovery_at = qcm.time.now() + COOLDOWN
        self.recovered = false
        if self.recovery_failures >= 2 then not_auth() end
        local api = require('api.middle.account.token.refresh').new(path)
        local ok, result = pcall(client._send, client, api, 30)
        if not ok then
            self.recovery_failures = self.recovery_failures + 1
            qcm.debug {component = 'ncm.session', event = 'recovery_failed'}
            error(result, 0)
        end
        qcm.debug {component = 'ncm.session', event = 'recovery_result', code = result.code,
            action = type(result.data) == 'table' and result.data.action or nil}
        if result.code ~= 200 or type(result.data) ~= 'table' then
            self.recovery_failures = self.recovery_failures + 1
            not_auth()
        end
        local data = result.data
        if data.action == 1 then
            self.recovery_failures, self.recovered = 0, true
            self:save()
            self.revision = self.revision + 1
            return
        end
        if data.action == 2 or data.action == 3 then
            not_auth(data.message, data.action == 3 and data.jumpUrl or nil)
        end
        self.recovery_failures = self.recovery_failures + 1
        not_auth('Unexpected session recovery response')
    end)
end
return Session
