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

    localparam DEPTH = 2**ADDR_WIDTH;
    localparam ADDR_MSB = ADDR_WIDTH;

    // Write domain signals
    reg [ADDR_WIDTH:0] wr_ptr;
    reg [ADDR_WIDTH:0] wr_ptr_gray;
    reg [ADDR_WIDTH:0] wr_ptr_gray_sync [SYNC_STAGES-1:0];
    reg [ADDR_WIDTH:0] rd_ptr_gray_sync [SYNC_STAGES-1:0];

    // Read domain signals
    reg [ADDR_WIDTH:0] rd_ptr;
    reg [ADDR_WIDTH:0] rd_ptr_gray;
    reg [ADDR_WIDTH:0] wr_ptr_gray_sync_r;

    // Memory array
    reg [DATA_WIDTH-1:0] mem [DEPTH-1:0];

    // Write domain logic
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wr_ptr <= 0;
            wr_ptr_gray <= 0;
        end else if (winc && !wfull) begin
            wr_ptr <= wr_ptr + 1;
            wr_ptr_gray <= (wr_ptr + 1) ^ ((wr_ptr + 1) >> 1);
        end
    end

    // Gray code synchronization for write pointer
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            wr_ptr_gray_sync <= '{default: 0};
        end else begin
            wr_ptr_gray_sync[0] <= wr_ptr_gray;
            for (int i = 1; i < SYNC_STAGES; i = i + 1) begin
                wr_ptr_gray_sync[i] <= wr_ptr_gray_sync[i-1];
            end
        end
    end

    // Read domain logic
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rd_ptr <= 0;
            rd_ptr_gray <= 0;
        end else if (rinc && !rempty) begin
            rd_ptr <= rd_ptr + 1;
            rd_ptr_gray <= (rd_ptr + 1) ^ ((rd_ptr + 1) >> 1);
        end
    end

    // Gray code synchronization for read pointer
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            rd_ptr_gray_sync <= '{default: 0};
        end else begin
            rd_ptr_gray_sync[0] <= rd_ptr_gray;
            for (int i = 1; i < SYNC_STAGES; i = i + 1) begin
                rd_ptr_gray_sync[i] <= rd_ptr_gray_sync[i-1];
            end
        end
    end

    // Synchronize read pointer gray code to write domain
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wr_ptr_gray_sync_r <= 0;
        end else begin
            wr_ptr_gray_sync_r <= rd_ptr_gray_sync[SYNC_STAGES-1];
        end
    end

    // Calculate full flag
    assign wfull = (wr_ptr_gray == (wr_ptr_gray_sync_r ^ (wr_ptr_gray_sync_r >> 1)));

    // Calculate empty flag
    assign rempty = (rd_ptr_gray == wr_ptr_gray_sync[SYNC_STAGES-1]);

    // Write data to memory
    always @(posedge wclk) begin
        if (winc && !wfull) begin
            mem[wr_ptr[ADDR_MSB-1:0]] <= wdata;
        end
    end

    // Read data from memory
    always @(posedge rclk) begin
        if (rinc && !rempty) begin
            rdata <= mem[rd_ptr[ADDR_MSB-1:0]];
        end
    end

    // Debug outputs
    assign waddr = wr_ptr;
    assign raddr = rd_ptr;

endmodule
