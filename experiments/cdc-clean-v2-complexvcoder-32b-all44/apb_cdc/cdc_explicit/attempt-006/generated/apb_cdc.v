module apb_cdc #(
    parameter ADDR_WIDTH = 8,
    parameter DATA_WIDTH = 32,
    parameter LOG_DEPTH = 1
)(
    input                      src_pclk_i,
    input                      src_preset_ni,
    input                      src_psel_i,
    input                      src_penable_i,
    input                      src_pwrite_i,
    input  [ADDR_WIDTH-1:0]    src_paddr_i,
    input  [DATA_WIDTH-1:0]    src_pwdata_i,
    input  [DATA_WIDTH/8-1:0]  src_pstrb_i,
    input  [2:0]               src_pprot_i,
    output                     src_pready_o,
    output [DATA_WIDTH-1:0]    src_prdata_o,
    output                     src_pslverr_o,
    input                      dst_pclk_i,
    input                      dst_preset_ni,
    output                     dst_psel_o,
    output                     dst_penable_o,
    output                     dst_pwrite_o,
    output [ADDR_WIDTH-1:0]    dst_paddr_o,
    output [DATA_WIDTH-1:0]    dst_pwdata_o,
    output [DATA_WIDTH/8-1:0]  dst_pstrb_o,
    output [2:0]               dst_pprot_o,
    input                      dst_pready_i,
    input  [DATA_WIDTH-1:0]    dst_prdata_i,
    input                      dst_pslverr_i
);

    // Internal signals
    wire [DATA_WIDTH + ADDR_WIDTH + (DATA_WIDTH/8) + 5 - 1:0] req_fifo_wdata;
    wire [DATA_WIDTH + ADDR_WIDTH + (DATA_WIDTH/8) + 5 - 1:0] req_fifo_rdata;
    wire [DATA_WIDTH - 1:0] resp_fifo_wdata;
    wire [DATA_WIDTH - 1:0] resp_fifo_rdata;
    wire req_fifo_wvalid;
    wire req_fifo_rready;
    wire req_fifo_rvalid;
    wire req_fifo_wready;
    wire resp_fifo_wvalid;
    wire resp_fifo_rready;
    wire resp_fifo_rvalid;
    wire resp_fifo_wready;

    // Pack the request data into a single bus for the FIFO
    assign req_fifo_wdata = {
        src_pprot_i,
        src_pstrb_i,
        src_pwdata_i,
        src_paddr_i,
        src_pwrite_i,
        src_penable_i,
        src_psel_i
    };

    // Unpack the request data from the FIFO
    assign dst_psel_o = req_fifo_rdata[0];
    assign dst_penable_o = req_fifo_rdata[1];
    assign dst_pwrite_o = req_fifo_rdata[2];
    assign dst_paddr_o = req_fifo_rdata[ADDR_WIDTH + 2:3];
    assign dst_pwdata_o = req_fifo_rdata[ADDR_WIDTH + DATA_WIDTH + 2:ADDR_WIDTH + 3];
    assign dst_pstrb_o = req_fifo_rdata[ADDR_WIDTH + DATA_WIDTH + (DATA_WIDTH/8) + 2:ADDR_WIDTH + DATA_WIDTH + 3];
    assign dst_pprot_o = req_fifo_rdata[ADDR_WIDTH + DATA_WIDTH + (DATA_WIDTH/8) + 5:ADDR_WIDTH + DATA_WIDTH + (DATA_WIDTH/8) + 3];

    // Pack the response data into a single bus for the FIFO
    assign resp_fifo_wdata = dst_prdata_i;

    // Unpack the response data from the FIFO
    assign src_prdata_o = resp_fifo_rdata;

    // Ready signals
    assign src_pready_o = req_fifo_wready;
    assign req_fifo_wvalid = src_psel_i && src_penable_i;
    assign req_fifo_rready = dst_pready_i;
    assign resp_fifo_rready = src_pready_o;

    // Instantiate the request FIFO
    async_fifo #(
        .WIDTH(DATA_WIDTH + ADDR_WIDTH + (DATA_WIDTH/8) + 5),
        .LOG_DEPTH(LOG_DEPTH)
    ) req_fifo_inst (
        .wclk(src_pclk_i),
        .wrst_n(src_preset_ni),
        .wdata(req_fifo_wdata),
        .wvalid(req_fifo_wvalid),
        .wready(req_fifo_wready),
        .rclk(dst_pclk_i),
        .rrst_n(dst_preset_ni),
        .rdata(req_fifo_rdata),
        .rvalid(req_fifo_rvalid),
        .rready(req_fifo_rready)
    );

    // Instantiate the response FIFO
    async_fifo #(
        .WIDTH(DATA_WIDTH),
        .LOG_DEPTH(LOG_DEPTH)
    ) resp_fifo_inst (
        .wclk(dst_pclk_i),
        .wrst_n(dst_preset_ni),
        .wdata(resp_fifo_wdata),
        .wvalid(resp_fifo_wvalid),
        .wready(resp_fifo_wready),
        .rclk(src_pclk_i),
        .rrst_n(src_preset_ni),
        .rdata(resp_fifo_rdata),
        .rvalid(resp_fifo_rvalid),
        .rready(resp_fifo_rready)
    );

    // Instantiate the ready signal synchronizer
    async_sync ready_sync_inst (
        .clk(dst_pclk_i),
        .rst_n(dst_preset_ni),
        .async_in(dst_pready_i),
        .out_clk(src_pclk_i),
        .out_rst_n(src_preset_ni),
        .sync_out(src_pready_o)
    );

    // Instantiate the slave error signal synchronizer
    async_sync slverr_sync_inst (
        .clk(dst_pclk_i),
        .rst_n(dst_preset_ni),
        .async_in(dst_pslverr_i),
        .out_clk(src_pclk_i),
        .out_rst_n(src_preset_ni),
        .sync_out(src_pslverr_o)
    );

endmodule

// Async FIFO module
module async_fifo #(
    parameter WIDTH = 32,
    parameter LOG_DEPTH = 1
)(
    input                      wclk,
    input                      wrst_n,
    input  [WIDTH-1:0]         wdata,
    input                      wvalid,
    output                     wready,
    input                      rclk,
    input                      rrst_n,
    output [WIDTH-1:0]         rdata,
    output                     rvalid,
    input                      rready
);

    // FIFO depth
    localparam DEPTH = 1 << LOG_DEPTH;

    // FIFO signals
    reg [WIDTH-1:0] mem [0:DEPTH-1];
    reg [$clog2(DEPTH)-1:0] wr_ptr, wr_ptr_gray, wr_ptr_gray_sync;
    reg [$clog2(DEPTH)-1:0] rd_ptr, rd_ptr_gray;
    reg [WIDTH-1:0] rd_data;
    reg rvalid_reg;

    // Gray code conversion
    function [$clog2(DEPTH)-1:0] bin2gray;
        input [$clog2(DEPTH)-1:0] bin;
        bin2gray = bin ^ (bin >> 1);
    endfunction

    // Write side logic
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wr_ptr <= 0;
            wr_ptr_gray <= 0;
        end else if (wready && wvalid) begin
            mem[wr_ptr] <= wdata;
            wr_ptr <= wr_ptr + 1;
            wr_ptr_gray <= bin2gray(wr_ptr + 1);
        end
    end

    // Synchronize write pointer to read clock domain
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n)
            wr_ptr_gray_sync <= 0;
        else
            wr_ptr_gray_sync <= wr_ptr_gray;
    end

    // Read side logic
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rd_ptr <= 0;
            rd_ptr_gray <= 0;
            rd_data <= 0;
            rvalid_reg <= 0;
        end else if (rready && rvalid) begin
            rd_ptr <= rd_ptr + 1;
            rd_ptr_gray <= bin2gray(rd_ptr + 1);
            rd_data <= mem[rd_ptr];
        end
    end

    // Calculate FIFO status
    wire [$clog2(DEPTH):0] wr_ptr_bin_sync;
    wire [$clog2(DEPTH):0] rd_ptr_bin;

    // Convert gray code to binary
    function [$clog2(DEPTH):0] gray2bin;
        input [$clog2(DEPTH):0] gray;
        integer i;
        reg [$clog2(DEPTH):0] bin;
        begin
            bin = gray[$clog2(DEPTH)];
            for (i = $clog2(DEPTH) - 1; i >= 0; i = i - 1)
                bin[i] = bin[i + 1] ^ gray[i];
            gray2bin = bin;
        end
    endfunction

    assign wr_ptr_bin_sync = gray2bin(wr_ptr_gray_sync);
    assign rd_ptr_bin = gray2bin(rd_ptr_gray);

    // FIFO flags
    wire full;
    wire empty;

    assign full = (wr_ptr_bin_sync[$clog2(DEPTH) - 1:0] == rd_ptr_bin[$clog2(DEPTH) - 1:0]) && (wr_ptr_bin_sync[$clog2(DEPTH)] != rd_ptr_bin[$clog2(DEPTH)]);
    assign empty = (wr_ptr_bin_sync[$clog2(DEPTH) - 1:0] == rd_ptr_bin[$clog2(DEPTH) - 1:0]) && (wr_ptr_bin_sync[$clog2(DEPTH)] == rd_ptr_bin[$clog2(DEPTH)]);

    // FIFO control signals
    assign wready = !full;
    assign rvalid = rvalid_reg;
    assign rvalid_reg = !empty && (rready || rvalid_reg);

    // Output data
    assign rdata = rd_data;

endmodule

// Async sync module
module async_sync (
    input clk,
    input rst_n,
    input async_in,
    input out_clk,
    input out_rst_n,
    output sync_out
);

    // Synchronized signal
    reg sync_reg1, sync_reg2;

    // Synchronize input to output clock domain
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sync_reg1 <= 0;
            sync_reg2 <= 0;
        end else begin
            sync_reg1 <= async_in;
            sync_reg2 <= sync_reg1;
        end
    end

    // Assign synchronized output
    assign sync_out = sync_reg2;

endmodule
