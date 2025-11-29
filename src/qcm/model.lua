---@class QcmAlbumModel
---@field id integer
---@field name string
---@field sort_name string?
---@field publish_time integer
---@field added_time string?
---@field track_count integer
---@field description string
---@field company string
---@field edit_time string|osdate?

---@class QcmArtistModel
---@field id integer
---@field name string
---@field sort_name string?
---@field description string
---@field album_count integer?
---@field music_count integer?
---@field edit_time string|osdate?

---@class QcmImageModel
---@field id integer
---@field item_id integer
---@field image_type string | integer
---@field db string?
---@field fresh string?
---@field timestamp string?

---@class QcmSongModel
---@field id integer
---@field name string
---@field sort_name string?
---@field album_id integer?
---@field track_number integer
---@field disc_number integer
---@field duration integer Duration in milliseconds
---@field can_play boolean?
---@field popularity number
---@field publish_time integer
---@field tags table?
---@field edit_time string|osdate?

---@class QcmItemModel
---@field id? integer
---@field provider_id? integer
---@field native_id string
---@field library_id integer|nil
---@field type QcmEmItemType|string
---@field created_at? string|osdate?
---@field updated_at? string|osdate?
---@field last_synced_at? string|osdate?

---@class QcmLibraryModel
---@field id? integer
---@field library_id integer
---@field provider_id integer
---@field native_id string

---@class QcmDynamicModel
---@field id integer
---@field favorite_at integer|nil
---@field is_external boolean

---@class QcmRemoteMixModel
---@field id integer
---@field name string
---@field description? string
---@field mix_type string
