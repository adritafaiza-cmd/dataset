module isochronous_4phase_handshake (
    input  src_clk_i,
    input  src_rst_ni,
    input  src_valid_i,
    output src_ready_o,
    input  dst_clk_i,
    input  dst_rst_ni,
    output dst_valid_o,
    input  dst_ready_i
);

reg src_valid_sync;
reg src_valid_sync2;
reg dst_ready_sync;
reg dst_ready_sync2;
reg src_valid_pulse;
reg dst_valid_pulse;

always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (~src_rst_ni) begin
        src_valid_sync <= 1'b0;
        src_valid_sync2 <= 1'b0;
    end else begin
        src_valid_sync <= src_valid_i;
        src_valid_sync2 <= src_valid_sync;
    end
end

always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (~dst_rst_ni) begin
        dst_ready_sync <= 1'b0;
        dst_ready_sync2 <= 1'b0;
    end else begin
        dst_ready_sync <= dst_ready_i;
        dst_ready_sync2 <= dst_ready_sync;
    end
end

always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (~src_rst_ni) begin
        src_valid_pulse <= 1'b0;
    end else if (src_valid_i && ~src_valid_sync2) begin
        src_valid_pulse <= 1'b1;
    end else if (~src_valid_i && src_valid_sync2) begin
        src_valid_pulse <= 1'b0;
    end
end

always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (~dst_rst_ni) begin
        dst_valid_pulse <= 1'b0;
    end else if (dst_ready_i && ~dst_ready_sync2) begin
        dst_valid_pulse <= 1'b1;
    end else if (~dst_ready_i && dst_ready_sync2) begin
        dst_valid_pulse <= 1'b0;
    end
end

assign src_ready_o = dst_ready_sync2;
assign dst_valid_o = src_valid_sync2;

endmodule
