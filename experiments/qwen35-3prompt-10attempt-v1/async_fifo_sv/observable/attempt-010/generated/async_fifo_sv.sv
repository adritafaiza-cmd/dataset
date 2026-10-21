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
    localparam GRAY_WIDTH     = ADDR_WIDTH_LOG;
    
    // Internal registers for write side
    reg [ADDR_WIDTH_LOG-1:0] w_ptr;
    reg [ADDR_WIDTH_LOG-1:0] w_tail;
    reg [ADDR_WIDTH_LOG-1:0] w_gray;
    reg                     w_full;
    
    // Internal registers for read side
    reg [ADDR_WIDTH_LOG-1:0] r_ptr;
    reg [ADDR_WIDTH_LOG-1:0] r_head;
    reg [ADDR_WIDTH_LOG-1:0] r_gray;
    reg                     r_empty;
    
    // FIFO Memory
    reg [DATA_WIDTH-1:0] mem [0: (1<<ADDR_WIDTH)-1];
    
    // Write Address Counter (Gray encoded)
    always_ff @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            w_ptr <= 0;
            w_tail <= 0;
            w_full <= 1'b0;
        end else begin
            if (winc && !wfull) begin
                w_ptr <= w_ptr + 1'b1;
                w_full <= (w_ptr == (1<<ADDR_WIDTH) - 1'b1);
            end
        end
    end

    // Read Address Counter (Gray encoded)
    always_ff @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            r_ptr <= 0;
            r_head <= 0;
            r_empty <= 1'b1;
        end else begin
            if (rinc && !r_empty) begin
                r_ptr <= r_ptr + 1'b1;
                r_empty <= (r_ptr == (1<<ADDR_WIDTH) - 1'b1);
            end
        end
    end

    // Write Pointer Gray Encoder
    always_ff @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            w_gray <= 0;
        end else begin
            w_gray <= w_ptr ^ (w_ptr >> 1);
        end
    end

    // Read Pointer Gray Encoder
    always_ff @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            r_gray <= 0;
        end else begin
            r_gray <= r_ptr ^ (r_ptr >> 1);
        end
    end

    // Write Data Storage
    always_ff @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            mem <= '0;
        end else if (winc && !wfull) begin
            mem[w_ptr] <= wdata;
        end
    end

    // Clock Domain Crossing: Write Pointer to Read Domain
    wire [GRAY_WIDTH-1:0] w_ptr_synced;
    wire [GRAY_WIDTH-1:0] w_tail_synced;
    wire [GRAY_WIDTH-1:0] w_gray_synced;
    wire w_full_synced;

    // Write Pointer to Read Domain
    genvar i;
    for (i = 0; i < SYNC_STAGES; i = i + 1) begin : stage_write_ptr
        wire [GRAY_WIDTH-1:0] w_ptr_stage;
        wire [GRAY_WIDTH-1:0] w_tail_stage;
        wire [GRAY_WIDTH-1:0] w_gray_stage;
        wire w_full_stage;
        
        always_ff @(posedge rclk or negedge rrst_n) begin
            if (!rrst_n) begin
                w_ptr_stage <= 0;
                w_tail_stage <= 0;
                w_gray_stage <= 0;
                w_full_stage <= 0;
            end else begin
                w_ptr_stage <= w_ptr_synced;
                w_tail_stage <= w_tail_synced;
                w_gray_stage <= w_gray_synced;
                w_full_stage <= w_full_synced;
            end
        end
        
        assign w_ptr_synced = w_ptr_stage;
        assign w_tail_synced = w_tail_stage;
        assign w_gray_synced = w_gray_stage;
        assign w_full_synced = w_full_stage;
    end

    // Clock Domain Crossing: Read Pointer to Write Domain
    wire [GRAY_WIDTH-1:0] r_ptr_synced;
    wire [GRAY_WIDTH-1:0] r_head_synced;
    wire [GRAY_WIDTH-1:0] r_gray_synced;
    wire r_empty_synced;

    for (i = 0; i < SYNC_STAGES; i = i + 1) begin : stage_read_ptr
        wire [GRAY_WIDTH-1:0] r_ptr_stage;
        wire [GRAY_WIDTH-1:0] r_head_stage;
        wire [GRAY_WIDTH-1:0] r_gray_stage;
        wire r_empty_stage;
        
        always_ff @(posedge wclk or negedge wrst_n) begin
            if (!wrst_n) begin
                r_ptr_stage <= 0;
                r_head_stage <= 0;
                r_gray_stage <= 0;
                r_empty_stage <= 0;
            end else begin
                r_ptr_stage <= r_ptr_synced;
                r_head_stage <= r_head_synced;
                r_gray_stage <= r_gray_synced;
                r_empty_stage <= r_empty_synced;
            end
        end
        
        assign r_ptr_synced = r_ptr_stage;
        assign r_head_synced = r_head_stage;
        assign r_gray_synced = r_gray_stage;
        assign r_empty_synced = r_empty_stage;
    end

    // Read Data Output
    assign rdata = mem[r_ptr];

    // Empty Flag Logic
    assign r_empty = (r_ptr == r_head);

    // Full Flag Logic
    assign wfull = w_full_synced;
    assign waddr = w_ptr;
    assign raddr = r_ptr;
    assign rempty = r_empty_synced;

endmodule
```<|im_end|>
