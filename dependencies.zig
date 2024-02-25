pub const std = @import("std");

pub const windows = @cImport({
    @cInclude("windows.h");
});
