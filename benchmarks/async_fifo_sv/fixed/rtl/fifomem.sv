//==============================================================================
// File: fifomem.sv
// Description: Dual-port RAM for FIFO storage
//==============================================================================

module fifomem #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 4,
    parameter DEPTH = 1 << ADDR_WIDTH
)(
    input  wire                    wclk,
    input  wire                    wfull,
    input  wire                    winc,
    input  wire [ADDR_WIDTH-1:0]   waddr,
    input  wire [DATA_WIDTH-1:0]   wdata,
    input  wire                    rclk,
    input  wire                    rrst_n,
    input  wire                    rinc,
    input  wire                    rempty,
    input  wire [ADDR_WIDTH-1:0]   raddr,
    output reg                     data_hold,
    output reg  [DATA_WIDTH-1:0]   rdata
);

    // Memory array
    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];

    (* ASYNC_REG = "TRUE" *) reg [DATA_WIDTH-1:0] payload_meta_q, payload_sync_q;
    reg [1:0] sample_wait_q;
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            payload_meta_q <= {DATA_WIDTH{1'b0}};
            payload_sync_q <= {DATA_WIDTH{1'b0}};
        end else begin
            payload_meta_q <= mem[raddr];
            payload_sync_q <= payload_meta_q;
        end
    end

    // Write operation
    always @(posedge wclk) begin
        if (winc && !wfull)
            mem[waddr] <= wdata;
    end

    // Sample the memory once, when a stored word is waiting and the
    // previous sample has been consumed. An every-cycle read of mem
    // on rclk is still CDC_NO_SYNC. data_hold falls for one read
    // clock after an accept so the next sample sees the new address.
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rdata <= {DATA_WIDTH{1'b0}};
            data_hold <= 1'b0;
            sample_wait_q <= 0;
        end else if (!data_hold && !rempty) begin
            if (sample_wait_q == 2) begin
            rdata <= payload_sync_q;
            data_hold <= 1'b1;
            sample_wait_q <= 0;
            end else sample_wait_q <= sample_wait_q + 1'b1;
        end else if (data_hold && rinc) begin
            data_hold <= 1'b0;
            sample_wait_q <= 0;
        end else sample_wait_q <= 0;
    end

    // Initialize memory for simulation
    integer i;
    initial begin
        for (i = 0; i < DEPTH; i = i + 1)
            mem[i] = '0;
    end

endmodule