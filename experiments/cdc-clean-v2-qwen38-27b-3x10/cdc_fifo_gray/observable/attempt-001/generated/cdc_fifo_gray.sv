module cdc_fifo_gray #(
    parameter WIDTH = 8,
    parameter LOG_DEPTH = 3,
    parameter SYNC_STAGES = 2
)(
    input                  src_rst_ni,
    input                  src_clk_i,
    input  [WIDTH-1:0]     src_data_i,
    input                  src_valid_i,
    output                 src_ready_o,
    input                  dst_rst_ni,
    input                  dst_clk_i,
    output [WIDTH-1:0]     dst_data_o,
    output                 dst_valid_o,
    input                  dst_ready_i
);

    localparam DEPTH = 1 << LOG_DEPTH;
    localparam PTR_W = LOG_DEPTH + 1;

    // Write pointer (binary) in source domain
    reg [PTR_W-1:0] wr_ptr_bin;
    // Read pointer (binary) in destination domain
    reg [PTR_W-1:0] rd_ptr_bin;

    // Gray code pointers
    wire [PTR_W-1:0] wr_ptr_gray = wr_ptr_bin ^ {wr_ptr_bin[PTR_W-1:1], {1'b0}};
    wire [PTR_W-1:0] rd_ptr_gray = rd_ptr_bin ^ {rd_ptr_bin[PTR_W-1:1], {1'b0}};

    // Synchronize write pointer gray to destination domain
    reg [PTR_W-1:0] wr_ptr_gray_dst;
    reg [PTR_W-1:0] wr_ptr_gray_dst_sync [0:SYNC_STAGES-1];

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            wr_ptr_gray_dst_sync[0] <= {PTR_W{1'b0}};
            wr_ptr_gray_dst_sync[1] <= {PTR_W{1'b0}};
            wr_ptr_gray_dst <= {PTR_W{1'b0}};
        end else begin
            wr_ptr_gray_dst_sync[0] <= wr_ptr_gray;
            wr_ptr_gray_dst_sync[1] <= wr_ptr_gray_dst_sync[0];
            wr_ptr_gray_dst <= wr_ptr_gray_dst_sync[1];
        end
    end

    // Synchronize read pointer gray to source domain
    reg [PTR_W-1:0] rd_ptr_gray_src;
    reg [PTR_W-1:0] rd_ptr_gray_src_sync [0:SYNC_STAGES-1];

    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            rd_ptr_gray_src_sync[0] <= {PTR_W{1'b0}};
            rd_ptr_gray_src_sync[1] <= {PTR_W{1'b0}};
            rd_ptr_gray_src <= {PTR_W{1'b0}};
        end else begin
            rd_ptr_gray_src_sync[0] <= rd_ptr_gray;
            rd_ptr_gray_src_sync[1] <= rd_ptr_gray_src_sync[0];
            rd_ptr_gray_src <= rd_ptr_gray_src_sync[1];
        end
    end

    // Convert gray to binary for comparison
    function [PTR_W-1:0] gray2bin;
        input [PTR_W-1:0] gray;
        integer i;
        begin
            gray2bin[PTR_W-1] = gray[PTR_W-1];
            for (i = PTR_W-2; i >= 0; i = i - 1)
                gray2bin[i] = gray2bin[i+1] ^ gray[i];
        end
    endfunction

    wire [PTR_W-1:0] wr_ptr_gray_dst_bin = gray2bin(wr_ptr_gray_dst);
    wire [PTR_W-1:0] rd_ptr_gray_src_bin = gray2bin(rd_ptr_gray_src);

    // FIFO status
    wire full = (wr_ptr_gray == {~rd_ptr_gray_src[PTR_W-1], rd_ptr_gray_src[PTR_W-2:0]});
    wire empty = (rd_ptr_gray == wr_ptr_gray);

    // Source side: ready is high when not full
    assign src_ready_o = ~full;

    // Write to memory
    reg [WIDTH-1:0] mem [0:DEPTH-1];
    reg [LOG_DEPTH-1:0] wr_addr;

    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            wr_ptr_bin <= {PTR_W{1'b0}};
            wr_addr <= {LOG_DEPTH{1'b0}};
        end else if (src_valid_i && src_ready_o) begin
            mem[wr_addr] <= src_data_i;
            wr_ptr_bin <= wr_ptr_bin + 1'b1;
            wr_addr <= wr_addr + 1'b1;
        end
    end

    // Destination side: read from memory
    reg [LOG_DEPTH-1:0] rd_addr;
    reg [WIDTH-1:0] rd_data_reg;
    reg rd_valid_reg;

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            rd_ptr_bin <= {PTR_W{1'b0}};
            rd_addr <= {LOG_DEPTH{1'b0}};
            rd_data_reg <= {WIDTH{1'b0}};
            rd_valid_reg <= 1'b0;
        end else begin
            if (dst_ready_i && rd_valid_reg) begin
                // Consume current data, prepare next
                rd_ptr_bin <= rd_ptr_bin + 1'b1;
                rd_addr <= rd_addr + 1'b1;
                rd_valid_reg <= (rd_ptr_gray != wr_ptr_gray_dst);
                if (rd_ptr_gray != wr_ptr_gray_dst)
                    rd_data_reg <= mem[rd_addr + 1'b1];
            end else if (!rd_valid_reg && (rd_ptr_gray != wr_ptr_gray_dst)) begin
                // Load first available data
                rd_data_reg <= mem[rd_addr];
                rd_valid_reg <= 1'b1;
            end
        end
    end

    assign dst_data_o = rd_data_reg;
    assign dst_valid_o = rd_valid_reg;

endmodule
