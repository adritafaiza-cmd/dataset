// =============================================================================
// APB Clock Domain Crossing Bridge
// =============================================================================
//
// This module bridges APB transfers between two asynchronous clock domains.
// It uses a handshake protocol with a FIFO to transfer APB transactions.
//
// =============================================================================

`timescale 1ns / 1ps

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

    // ========================================================================
    // FIFO Control Signals
    // ========================================================================
    wire [LOG_DEPTH:0] src_wr_ptr;
    wire [LOG_DEPTH:0] dst_rd_ptr;
    wire               fifo_full;
    wire               fifo_empty;

    // ========================================================================
    // Source Domain: APB Master Interface
    // ========================================================================

    // State machine states
    localparam S_IDLE    = 1'b0;
    localparam S_ACCESS  = 1'b1;

    reg  [1:0] src_state;
    reg  [1:0] src_state_next;

    // FIFO write enable
    wire src_wr_en = (src_state == S_IDLE) && src_psel_i && !fifo_full;

    // FIFO read enable (from destination)
    wire src_rd_en;

    // ========================================================================
    // FIFO Implementation
    // ========================================================================

    // FIFO storage
    reg [DATA_WIDTH-1:0] fifo_mem [0:(1<<LOG_DEPTH)-1];

    // FIFO write address
    wire [LOG_DEPTH-1:0] src_wr_addr = src_wr_ptr[LOG_DEPTH-1:0];

    // FIFO read address
    wire [LOG_DEPTH-1:0] dst_rd_addr = dst_rd_ptr[LOG_DEPTH-1:0];

    // FIFO full/empty conditions
    assign fifo_full  = (src_wr_ptr[LOG_DEPTH] != dst_rd_ptr[LOG_DEPTH]) &&
                        (src_wr_ptr[LOG_DEPTH-1:0] == dst_rd_ptr[LOG_DEPTH-1:0]);
    assign fifo_empty = (src_wr_ptr == dst_rd_ptr);

    // ========================================================================
    // Source Domain Logic
    // ========================================================================

    // State machine
    always @(posedge src_pclk_i or negedge src_preset_ni) begin
        if (!src_preset_ni)
            src_state <= S_IDLE;
        else
            src_state <= src_state_next;
    end

    // Next state logic
    always @(*) begin
        src_state_next = src_state;
        case (src_state)
            S_IDLE: begin
                if (src_psel_i && !fifo_full)
                    src_state_next = S_ACCESS;
            end
            S_ACCESS: begin
                if (src_penable_i && src_pready_o)
                    src_state_next = S_IDLE;
            end
            default: src_state_next = S_IDLE;
        endcase
    end

    // APB ready signal
    assign src_pready_o = (src_state == S_ACCESS) && src_penable_i && !fifo_empty;

    // FIFO write logic
    always @(posedge src_pclk_i or negedge src_preset_ni) begin
        if (!src_preset_ni) begin
            src_wr_ptr <= {({LOG_DEPTH+1}{1'b0}});
        end else if (src_wr_en) begin
            fifo_mem[src_wr_addr] <= {src_pwrite_i, src_paddr_i, src_pwdata_i, src_pstrb_i, src_pprot_i};
            src_wr_ptr <= src_wr_ptr + 1'b1;
        end
    end

    // ========================================================================
    // Destination Domain Logic
    // ========================================================================

    // State machine states
    localparam D_IDLE    = 1'b0;
    localparam D_SETUP   = 1'b1;
    localparam D_ACCESS  = 1'b2;

    reg  [1:0] dst_state;
    reg  [1:0] dst_state_next;

    // FIFO read enable
    wire dst_rd_en = (dst_state == D_IDLE) && !fifo_empty;

    // FIFO write enable (from source)
    wire dst_wr_en;

    // ========================================================================
    // Destination Domain Logic
    // ========================================================================

    // State machine
    always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
        if (!dst_preset_ni)
            dst_state <= D_IDLE;
        else
            dst_state <= dst_state_next;
    end

    // Next state logic
    always @(*) begin
        dst_state_next = dst_state;
        case (dst_state)
            D_IDLE: begin
                if (!fifo_empty)
                    dst_state_next = D_SETUP;
            end
            D_SETUP: begin
                dst_state_next = D_ACCESS;
            end
            D_ACCESS: begin
                if (dst_pready_i)
                    dst_state_next = D_IDLE;
            end
            default: dst_state_next = D_IDLE;
        endcase
    end

    // APB signals
    assign dst_psel_o    = (dst_state == D_SETUP) || (dst_state == D_ACCESS);
    assign dst_penable_o = (dst_state == D_ACCESS);

    // FIFO read logic
    always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
        if (!dst_preset_ni) begin
            dst_rd_ptr <= {({LOG_DEPTH+1}{1'b0}});
        end else if (dst_rd_en) begin
            dst_rd_ptr <= dst_rd_ptr + 1'b1;
        end
    end

    // ========================================================================
    // Data Path
    // ========================================================================

    // Read data from FIFO
    wire [DATA_WIDTH*2+ADDR_WIDTH+DATA_WIDTH/8+2-1:0] fifo_data = fifo_mem[dst_rd_addr];

    // Extract fields
    assign dst_pwrite_o  = fifo_data[DATA_WIDTH*2+ADDR_WIDTH+DATA_WIDTH/8+1];
    assign dst_paddr_o   = fifo_data[DATA_WIDTH*2+ADDR_WIDTH+DATA_WIDTH/8:DATA_WIDTH+DATA_WIDTH/8+1];
    assign dst_pwdata_o  = fifo_data[DATA_WIDTH+DATA_WIDTH/8:DATA_WIDTH/8+1];
    assign dst_pstrb_o   = fifo_data[DATA_WIDTH/8:1];
    assign dst_pprot_o   = fifo_data[2:0];

    // Return data to source
    assign src_prdata_o  = dst_prdata_i;
    assign src_pslverr_o = dst_pslverr_i;

endmodule