const std = @import("std");
const net = std.net;
const debug = std.debug;
const mem = std.mem;
const os = std.os;

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var server = net.StreamServer.init(.{});
    defer server.deinit();

    const address = try net.Address.parseIp("127.0.0.1", 8000);

    try server.listen(address);

    while(true) {
        const connection = try server.accept();
        const reader = connection.stream.reader();
        const method = try reader.readUntilDelimiterAlloc(allocator, ' ', 65536);
        const path = try reader.readUntilDelimiterAlloc(allocator, ' ', 65536);
        const protocol = try reader.readUntilDelimiterAlloc(allocator, '\n', 65536);

        if(!mem.startsWith(u8, protocol,"HTTP/1.1")) {
            debug.print("Illegal method detected {s}\n", .{protocol});
            connection.stream.close();
            break;
        }

        try connection.stream.writer().writeAll("HTTP/1.1 200 OK\nAccept-Ranges: bytes\nContent-Length:17\nContent-Type: text/html\n\nyou are a menace.");
        connection.stream.close();
        debug.print("{s} {s} {s}\n", .{method, path, protocol});
        break;
    }

    server.close();
}