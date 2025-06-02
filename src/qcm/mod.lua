---@class QcmInner
---@field id integer? provider id
---@field device_id fun(self: QcmInner): string

---@class QcmResponse
---@field code integer HTTP response code
---@field body string response body
---@field headers table<string, string> HTTP headers

---@class QcmRequestBuilder
---@field headers fun(self: QcmRequestBuilder, headers: table<string, string> ): QcmRequestBuilder
---@field form fun(self: QcmRequestBuilder, body: string|table): QcmRequestBuilder
---@field query fun(self: QcmRequestBuilder, query: table<string, any>): QcmRequestBuilder
---@field timeout fun(self: QcmRequestBuilder, t: integer): QcmRequestBuilder
---@field send fun(self: QcmRequestBuilder): QcmResponse

---@class HttpClientBatch
---@field wait_one fun(self: HttpClientBatch): QcmResponse
---@field add fun(self: HttpClientBatch, req: QcmRequestBuilder): QcmResponse

---@class HttpClient
---@field get fun(self: HttpClient, url: string): QcmRequestBuilder
---@field post fun(self: HttpClient, url: string): QcmRequestBuilder
---@field new_batch fun(self: HttpClient): HttpClientBatch

---@class QcmSyncContext
---@field commit_album fun(count: integer)
---@field commit_artist fun(count: integer)
---@field commit_song fun(count: integer)
---@field sync_libraries fun(models: LibraryModel[]): integer[]
---@field sync_albums fun(models: AlbumModel[]): integer[]
---@field sync_artists fun(models: ArtistModel[]): integer[]
---@field sync_songs fun(models: SongModel[]): integer[]
---@field sync_images fun(models: ImageModel[])
---@field sync_song_album_ids fun(library_id: integer, ids: string[][])
---@field sync_album_artist_ids fun(models: AlbumModel[])
---@field sync_song_artist_ids fun(models: ArtistModel[])

---@class QcmHex
---@field encode_low fun(data: string): string
---@field encode_up fun(data: string): string

---@class QcmCryptoRsa
---@field encrypt fun(self: QcmCryptoRsa, data: string): string

---@class QcmCrypto
---@field md5 fun(data: string): string MD5 hash function
---@field digest fun(type: string, data: string): string
---@field encrypt fun(type: string, key: string, iv: string, data: string): string
---@field encode fun(data: string): string
---@field encode_block fun(data: string): string
---@field create_rsa fun(key: string): QcmCryptoRsa
---@field hex QcmHex

---@class QcmJson
---@field encode fun(value: any): string Encode value to JSON string
---@field decode fun(json: string): any Decode JSON string to value

---@class Qcm
---@field inner QcmInner Provider inner data
---@field get_http_client fun(): HttpClient Get HTTP client instance
---@field crypto QcmCrypto Cryptographic functions
---@field json QcmJson JSON utilities
---@field debug fun(value: any) Debug print value
---@field enum QcmEnum Item type enums

---@type Qcm
local M = qcm;

return M;
