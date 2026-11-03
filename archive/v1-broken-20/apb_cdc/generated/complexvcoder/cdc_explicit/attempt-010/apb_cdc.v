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
    reg [DATA_WIDTH-1:0] src_data;
    reg src_valid;
    wire dst_ready;
    wire [DATA_WIDTH-1:0] dst_data;
    wire dst_valid;

    // FIFO
    fifo #(
        .DATA_WIDTH(DATA_WIDTH),
        .LOG_DEPTH(LOG_DEPTH)
    ) apb_fifo (
        .clk(src_pclk_i),
        .reset_ni(src_preset_ni),
        .sink_data(src_data),
        .sink_valid(src_valid),
        .sink_ready(dst_ready),
        .source_data(dst_data),
        .source_valid(dst_valid)
    );

    // FSM
    fsm #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) apb_fsm (
        .clk(src_pclk_i),
        .reset_ni(src_preset_ni),
        .psel(src_psel_i),
        .penable(src_penable_i),
        .pwrite(src_pwrite_i),
        .paddr(src_paddr_i),
        .pwdata(src_pwdata_i),
        .pstrb(src_pstrb_i),
        .pprot(src_pprot_i),
        .src_pready(src_pready_o),
        .src_prdata(src_prdata_o),
        .src_pslverr(src_pslverr_o),
        .dst_psel(dst_psel_o),
        .dst_penable(dst_penable_o),
        .dst_pwrite(dst_pwrite_o),
        .dst_paddr(dst_paddr_o),
        .dst_pwdata(dst_pwdata_o),
        .dst_pstrb(dst_pstrb_o),
        .dst_pprot(dst_pprot_o),
        .dst_pready(dst_pready_i),
        .src_data(src_data),
        .src_valid(src_valid),
        .dst_ready(dst_ready),
        .dst_data(dst_data),
        .dst_valid(dst_valid)
    );

endmodule

module fifo #(
    parameter DATA_WIDTH = 32,
    parameter LOG_DEPTH = 1
)(
    input                      clk,
    input                      reset_ni,
    input  [DATA_WIDTH-1:0]    sink_data,
    input                      sink_valid,
    output                     sink_ready,
    output [DATA_WIDTH-1:0]    source_data,
    output                     source_valid
);

    reg [DATA_WIDTH-1:0] mem [0:((1<<LOG_DEPTH)-1)];
    reg [LOG_DEPTH:0] wr_ptr;
    reg [LOG_DEPTH:0] rd_ptr;
    reg [LOG_DEPTH:0] cnt;

    assign sink_ready = (cnt < (1<<LOG_DEPTH));

    always @(posedge clk or negedge reset_ni) begin
        if (!reset_ni) begin
            wr_ptr <= 0;
            rd_ptr <= 0;
            cnt <= 0;
            mem <= '{default:0};
        end else begin
            if (sink_valid && sink_ready) begin
                mem[wr_ptr] <= sink_data;
                wr_ptr <= wr_ptr + 1;
                cnt <= cnt + 1;
            end
            if (source_valid) begin
                rd_ptr <= rd_ptr + 1;
                cnt <= cnt - 1;
            end
        end
    end

    assign source_data = mem[rd_ptr];
    assign source_valid = (cnt > 0);

endmodule

module fsm #(
    parameter ADDR_WIDTH = 8,
    parameter DATA_WIDTH = 32
)(
    input                      clk,
    input                      reset_ni,
    input                      psel,
    input                      penable,
    input                      pwrite,
    input  [ADDR_WIDTH-1:0]    paddr,
    input  [DATA_WIDTH-1:0]    pwdata,
    input  [DATA_WIDTH/8-1:0]  pstrb,
    input  [2:0]               pprot,
    output                     src_pready,
    output [DATA_WIDTH-1:0]    src_prdata,
    output                     src_pslverr,
    output                     dst_psel,
    output                     dst_penable,
    output                     dst_pwrite,
    output [ADDR_WIDTH-1:0]    dst_paddr,
    output [DATA_WIDTH-1:0]    dst_pwdata,
    output [DATA_WIDTH/8-1:0]  dst_pstrb,
    output [2:0]               dst_pprot,
    input                      dst_pready,
    input  [DATA_WIDTH-1:0]    dst_prdata,
    input                      dst_pslverr,
    output                     src_data,
    output                     src_valid,
    input                      dst_ready,
    input  [DATA_WIDTH-1:0]    dst_data,
    input                      dst_valid
);

    // Internal signals
    reg [2:0] state;
    reg [2:0] next_state;
    reg [DATA_WIDTH-1:0] src_data_reg;
    reg src_valid_reg;
    reg [DATA_WIDTH-1:0] dst_data_reg;
    reg dst_valid_reg;

    // State encoding
    parameter IDLE = 3'b000,
             SETUP = 3'b001,
             ACCESS = 3'b010,
             DONE = 3'b011,
             RESET = 3'b100;

    always @(posedge clk or negedge reset_ni) begin
        if (!reset_ni) begin
            state <= RESET;
        end else begin
            state <= next_state;
        end
    end

    always @(*) begin
        next_state = state;
        src_pready = 1'b0;
        src_prdata = 0;
        src_pslverr = 0;
        dst_psel = 0;
        dst_penable = 0;
        dst_pwrite = 0;
        dst_paddr = 0;
        dst_pwdata = 0;
        dst_pstrb = 0;
        dst_pprot = 0;
        src_data = 0;
        src_valid = 0;
        src_data_reg = src_data_reg;
        src_valid_reg = src_valid_reg;
        dst_data_reg = 0;
        dst_valid_reg = 0;

        case (state)
            IDLE: begin
                if (psel && penable) begin
                    next_state = SETUP;
                    src_data_reg = pwdata;
                    src_valid_reg = 1'b1;
                end
            end
            SETUP: begin
                dst_psel = 1'b1;
                dst_penable = 1'b0;
                dst_pwrite = 1'b1;
                dst_paddr = paddr;
                dst_pwdata = src_data_reg;
                dst_pstrb = pstrb;
                dst_pprot = pprot;
                src_pready = 1'b0;
                if (dst_pready) begin
                    next_state = ACCESS;
                end
            end
            ACCESS: begin
                dst_psel = 1'b1;
                dst_penable = 1'b1;
                dst_pwrite = 1'b0;
                dst_paddr = paddr;
                src_pready = 1'b0;
                if (dst_pready) begin
                    next_state = DONE;
                    src_prdata = dst_prdata;
                    src_pslverr = dst_pslverr;
                end
            end
            DONE: begin
                src_pready = 1'b1;
                src_valid = 0;
                if (!psel || !penable) begin
                    next_state = IDLE;
                end
            end
            RESET: begin
                src_pready = 1'b0;
                src_valid = 0;
                dst_psel = 0;
                dst_penable = 0;
                dst_pwrite = 0;
                dst_paddr = 0;
                dst_pwdata = 0;
                dst_pstrb = 0;
                dst_pprot = 0;
                if (psel && penable) begin
                    next_state = IDLE;
                end
            end
        endcase
    end

endmodule
