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

    localparam DEPTH = 1 << ADDR_WIDTH;
    localparam PTR_WIDTH = ADDR_WIDTH + 1;

    // Write domain
    reg [PTR_WIDTH-1:0] wptr;
    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];

    // Read domain
    reg [PTR_WIDTH-1:0] rptr;

    // Synchronizers
    reg [PTR_WIDTH-1:0] wptr_sync [0:SYNC_STAGES-1];
    reg [PTR_WIDTH-1:0] rptr_sync [0:SYNC_STAGES-1];

    // Full/Empty logic
    wire wfull_int;
    wire rempty_int;

    // Write pointer increment
    wire winc_eff = winc & ~wfull_int;

    // Read pointer increment
    wire rinc_eff = rinc & ~rempty_int;

    // Write pointer update
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n)
            wptr <= {PTR_WIDTH{1'b0}};
        else if (winc_eff)
            wptr <= wptr + 1'b1;
    end

    // Read pointer update
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n)
            rptr <= {PTR_WIDTH{1'b0}};
        else if (rinc_eff)
            rptr <= rptr + 1'b1;
    end

    // Write to memory
    always @(posedge wclk) begin
        if (winc_eff)
            mem[wptr[ADDR_WIDTH-1:0]] <= wdata;
    end

    // Read from memory
    always @(posedge rclk) begin
        if (rinc_eff)
            rdata <= mem[rptr[ADDR_WIDTH-1:0]];
    end

    // Synchronize write pointer to read domain
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            wptr_sync[0] <= {PTR_WIDTH{1'b0}};
            for (int i = 1; i < SYNC_STAGES; i = i + 1)
                wptr_sync[i] <= {PTR_WIDTH{1'b0}};
        end
        else begin
            wptr_sync[0] <= wptr;
            for (int i = 1; i < SYNC_STAGES; i = i + 1)
                wptr_sync[i] <= wptr_sync[i-1];
        end
    end

    // Synchronize read pointer to write domain
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            rptr_sync[0] <= {PTR_WIDTH{1'b0}};
            for (int i = 1; i < SYNC_STAGES; i = i + 1)
                rptr_sync[i] <= {PTR_WIDTH{1'b0}};
        end
        else begin
            rptr_sync[0] <= rptr;
            for (int i = 1; i < SYNC_STAGES; i = i + 1)
                rptr_sync[i] <= rptr_sync[i-1];
        end
    end

    // Full condition: write pointer has lapped read pointer by DEPTH
    // In Gray code or binary with extra bit: full when upper bits differ and lower bits equal
    // Using binary pointers with extra bit:
    // wfull when wptr[ADDR_WIDTH] != rptr_sync[SYNC_STAGES-1][ADDR_WIDTH] 
    // and wptr[ADDR_WIDTH-1:0] == rptr_sync[SYNC_STAGES-1][ADDR_WIDTH-1:0]
    assign wfull_int = (wptr[ADDR_WIDTH] != rptr_sync[SYNC_STAGES-1][ADDR_WIDTH]) &&
                       (wptr[ADDR_WIDTH-1:0] == rptr_sync[SYNC_STAGES-1][ADDR_WIDTH-1:0]);

    // Empty condition: read pointer equals write pointer
    assign rempty_int = (rptr == wptr_sync[SYNC_STAGES-1]);

    // Outputs
    assign wfull = wfull_int;
    assign waddr = wptr;
    assign rempty = rempty_int;
    assign raddr = rptr;

endmodule
