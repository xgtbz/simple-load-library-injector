pub const std = @import("std");

pub const windows = @cImport({
    @cInclude("stdio.h");
    @cInclude("windows.h");
});
