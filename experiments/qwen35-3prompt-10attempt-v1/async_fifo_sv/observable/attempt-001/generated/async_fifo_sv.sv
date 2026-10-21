```systemverilog
module async_fifo #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 4,
    parameter SYNC_STAGES = 2
)(
    input  wire                    wclk,
    input  wire                    wrst_n,
    input  wire                    winc,
    input  wire [DATA_WIDTH-1:0]   wdata,
    output wire                    wfull,
    output wire [ADDR_WIDTH:0]     waddr,
    input  wire                    rclk,
    input  wire                    rrst_n,
    input  wire                    rinc,
    output wire [DATA_WIDTH-1:0]   rdata,
    output wire                    rempty,
    output wire [ADDR_WIDTH:0]     raddr
);

    localparam ADDR_WIDTH_LOG = ADDR_WIDTH + 1;
    localparam DATA_WIDTH_LOG = DATA_WIDTH;

    // Write side registers
    reg [ADDR_WIDTH_LOG-1:0] w_ptr;
    reg [ADDR_WIDTH_LOG-1:0] w_tail;
    reg [ADDR_WIDTH_LOG-1:0] w_cnt;
    reg [DATA_WIDTH-1:0]     w_data_reg;

    // Read side registers
    reg [ADDR_WIDTH_LOG-1:0] r_ptr;
    reg [ADDR_WIDTH_LOG-1:0] r_tail;
    reg [ADDR_WIDTH_LOG-1:0] r_cnt;
    reg [DATA_WIDTH-1:0]     r_data_reg;

    // Synchronizers for write pointer (read domain)
    wire [ADDR_WIDTH_LOG-1:0] w_ptr_sync_0;
    wire [ADDR_WIDTH_LOG-1:0] w_ptr_sync_1;
    wire [ADDR_WIDTH_LOG-1:0] w_tail_sync_0;
    wire [ADDR_WIDTH_LOG-1:0] w_tail_sync_1;

    // Synchronizers for read pointer (write domain)
    wire [ADDR_WIDTH_LOG-1:0] r_ptr_sync_0;
    wire [ADDR_WIDTH_LOG-1:0] r_ptr_sync_1;
    wire [ADDR_WIDTH_LOG-1:0] r_tail_sync_0;
    wire [ADDR_WIDTH_LOG-1:0] r_tail_sync_1;

    // Write side logic
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            w_ptr     <= 0;
            w_tail    <= 0;
            w_cnt     <= 0;
            w_data_reg <= 0;
            waddr     <= 0;
            wfull     <= 1'b1;
        end else begin
            w_ptr     <= w_ptr + 1'b1;
            w_tail    <= w_tail;
            w_cnt     <= w_cnt + 1'b1;
            w_data_reg <= wdata;
            waddr     <= w_ptr;

            if (w_cnt == (1 << ADDR_WIDTH_LOG)) begin
                wfull <= 1'b1;
            end else begin
                wfull <= 1'b0;
            end
        end
    end

    // Read side logic
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            r_ptr     <= 0;
            r_tail    <= 0;
            r_cnt     <= 0;
            r_data_reg <= 0;
            raddr     <= 0;
            rempty    <= 1'b1;
        end else begin
            r_ptr     <= r_ptr + 1'b1;
            r_tail    <= r_tail;
            r_cnt     <= r_cnt + 1'b1;
            r_data_reg <= r_data_reg;
            raddr     <= r_ptr;

            if (r_cnt == (1 << ADDR_WIDTH_LOG)) begin
                rempty <= 1'b1;
            end else begin
                rempty <= 1'b0;
            end
        end
    end

    // Synchronizers for write pointer (read domain)
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            w_ptr_sync_0 <= 0;
            w_ptr_sync_1 <= 0;
            w_tail_sync_0 <= 0;
            w_tail_sync_1 <= 0;
        end else begin
            w_ptr_sync_0 <= w_ptr;
            w_ptr_sync_1 <= w_ptr_sync_0;
            w_tail_sync_0 <= w_tail;
            w_tail_sync_1 <= w_tail_sync_0;
        end
    end

    // Synchronizers for read pointer (write domain)
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            r_ptr_sync_0 <= 0;
            r_ptr_sync_1 <= 0;
            r_tail_sync_0 <= 0;
            r_tail_sync_1 <= 0;
        end else begin
            r_ptr_sync_0 <= r_ptr;
            r_ptr_sync_1 <= r_ptr_sync_0;
            r_tail_sync_0 <= r_tail;
            r_tail_sync_1 <= r_tail_sync_0;
        end
    end

    // Full flag logic (in write domain)
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wfull <= 1'b1;
        end else begin
            if (w_cnt == (1 << ADDR_WIDTH_LOG)) begin
                wfull <= 1'b1;
            end else if (w_cnt == (1 << ADDR_WIDTH_LOG) - 1 && w_ptr == r_ptr_sync_1) begin
                wfull <= 1'b1;
            end else begin
                wfull <= 1'b0;
            end
        end
    end

    // Empty flag logic (in read domain)
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rempty <= 1'b1;
        end else begin
            if (r_cnt == (1 << ADDR_WIDTH_LOG)) begin
                rempty <= 1'b1;
            end else if (r_cnt == (1 << ADDR_WIDTH_LOG) - 1 && r_ptr == w_tail_sync_1) begin
                rempty <= 1'b1;
            end else begin
                rempty <= 1'b0;
            end
        end
    end

    // Data output logic (in read domain)
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rdata <= 0;
        end else begin
            if (rinc) begin
                rdata <= r_data_reg;
            end else begin
                rdata <= r_data_reg;
            end
        end
    end

    // Write enable logic (in write domain)
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            w_data_reg <= 0;
        end else begin
            if (winc && !wfull) begin
                w_data_reg <= wdata;
            end else begin
                w_data_reg <= w_data_reg;
            end
        end
    end

endmodule
```<|im_end|>
