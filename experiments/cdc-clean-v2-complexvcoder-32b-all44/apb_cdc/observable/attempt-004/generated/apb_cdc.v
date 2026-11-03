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
    wire [ADDR_WIDTH + DATA_WIDTH + DATA_WIDTH/8 + 3 + 1 - 1:0] req_data;
    wire req_push;
    wire req_fifo_full;
    wire req_fifo_empty;
    wire [ADDR_WIDTH + DATA_WIDTH + DATA_WIDTH/8 + 3 + 1 - 1:0] req_fifo_data;
    wire req_fifo_pop;

    wire [DATA_WIDTH + 1 - 1:0] resp_data;
    wire resp_push;
    wire resp_fifo_full;
    wire resp_fifo_empty;
    wire [DATA_WIDTH + 1 - 1:0] resp_fifo_data;
    wire resp_fifo_pop;

    wire dst_psel;
    wire dst_penable;
    wire dst_pwrite;
    wire [ADDR_WIDTH-1:0] dst_paddr;
    wire [DATA_WIDTH-1:0] dst_pwdata;
    wire [DATA_WIDTH/8-1:0] dst_pstrb;
    wire [2:0] dst_pprot;
    wire src_pready;
    wire [DATA_WIDTH-1:0] src_prdata;
    wire src_pslverr;
    wire req_valid;
    wire req_ready;
    wire resp_valid;
    wire resp_ready;

    // Request FIFO
    fifo #(
        .DATA_WIDTH(ADDR_WIDTH + DATA_WIDTH + DATA_WIDTH/8 + 3 + 1)
    ) req_fifo (
        .clk_i(src_pclk_i),
        .rst_ni(src_preset_ni),
        .data_i(req_data),
        .push_i(req_push),
        .full_o(req_fifo_full),
        .empty_o(req_fifo_empty),
        .data_o(req_fifo_data),
        .pop_i(req_fifo_pop)
    );

    // Response FIFO
    fifo #(
        .DATA_WIDTH(DATA_WIDTH + 1)
    ) resp_fifo (
        .clk_i(dst_pclk_i),
        .rst_ni(dst_preset_ni),
        .data_i(resp_data),
        .push_i(resp_push),
        .full_o(resp_fifo_full),
        .empty_o(resp_fifo_empty),
        .data_o(resp_fifo_data),
        .pop_i(resp_fifo_pop)
    );

    // Request valid and ready
    assign req_valid = src_psel_i & src_penable_i & ~req_fifo_full;
    assign req_ready = ~req_fifo_full;

    // Pack request data
    assign req_data = {src_pwrite_i, src_paddr_i, src_pwdata_i, src_pstrb_i, src_pprot_i};

    // Push request to FIFO
    assign req_push = req_valid & req_ready;

    // Unpack request data from FIFO
    assign {dst_pwrite, dst_paddr, dst_pwdata, dst_pstrb, dst_pprot} = req_fifo_data;

    // Destination APB signals
    assign dst_psel_o = ~req_fifo_empty;
    assign dst_penable_o = ~req_fifo_empty;

    // Response valid and ready
    assign resp_valid = ~resp_fifo_empty;
    assign resp_ready = ~resp_fifo_full;

    // Pack response data
    assign resp_data = {dst_prdata_i, dst_pslverr_i};

    // Push response to FIFO
    assign resp_push = dst_pready_i & resp_valid;

    // Unpack response data from FIFO
    assign {src_prdata, src_pslverr} = resp_fifo_data;

    // Source APB ready signal
    assign src_pready_o = resp_valid;

    // Source APB response signals
    assign src_prdata_o = src_prdata;
    assign src_pslverr_o = src_pslverr;

    // Pop signals for FIFOs
    assign req_fifo_pop = dst_psel_o & dst_penable_o & dst_pready_i;
    assign resp_fifo_pop = resp_ready;

endmodule

module fifo #(
    parameter DATA_WIDTH = 32
)(
    input                      clk_i,
    input                      rst_ni,
    input  [DATA_WIDTH-1:0]    data_i,
    input                      push_i,
    output reg                 full_o,
    output reg                 empty_o,
    output [DATA_WIDTH-1:0]    data_o,
    input                      pop_i
);

    // FIFO depth
    localparam DEPTH = 2**LOG_DEPTH;

    // FIFO memory
    reg [DATA_WIDTH-1:0] mem [DEPTH-1:0];

    // Pointers
    reg [$clog2(DEPTH)-1:0] wr_ptr;
    reg [$clog2(DEPTH)-1:0] rd_ptr;

    // Flags
    reg full_flag;
    reg empty_flag;

    // Write enable
    wire we = push_i & ~full_flag;

    // Read enable
    wire re = pop_i & ~empty_flag;

    // FIFO write operation
    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            wr_ptr <= 0;
            full_flag <= 0;
            empty_flag <= 1;
        end else if (we) begin
            mem[wr_ptr] <= data_i;
            wr_ptr <= wr_ptr + 1;
            empty_flag <= 0;
            if (wr_ptr == rd_ptr - 1)
                full_flag <= 1;
        end else if (re) begin
            wr_ptr <= wr_ptr;
            if (wr_ptr == rd_ptr + 1)
                empty_flag <= 1;
            if (wr_ptr == rd_ptr)
                full_flag <= 0;
        end
    end

    // FIFO read operation
    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            rd_ptr <= 0;
        end else if (re) begin
            rd_ptr <= rd_ptr + 1;
        end
    end

    // FIFO data output
    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni)
            data_o <= 0;
        else if (re)
            data_o <= mem[rd_ptr];
    end

    // FIFO full and empty flags
    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            full_o <= 0;
            empty_o <= 1;
        end else begin
            full_o <= full_flag;
            empty_o <= empty_flag;
        end
    end

endmodule
