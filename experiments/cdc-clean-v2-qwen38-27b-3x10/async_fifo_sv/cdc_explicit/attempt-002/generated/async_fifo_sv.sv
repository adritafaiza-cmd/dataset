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
    reg [PTR_WIDTH-1:0] rptr_w;
    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];
    reg [DATA_WIDTH-1:0] wdata_reg;
    reg wdata_valid;

    // Read domain
    reg [PTR_WIDTH-1:0] rptr;
    reg [PTR_WIDTH-1:0] wptr_r;
    reg [DATA_WIDTH-1:0] rdata_reg;
    reg rdata_valid;

    // Synchronizers
    reg [PTR_WIDTH-1:0] wptr_sync [0:SYNC_STAGES-1];
    reg [PTR_WIDTH-1:0] rptr_sync [0:SYNC_STAGES-1];

    // Write domain logic
    wire wfull_int = (wptr[ADDR_WIDTH] != rptr_w[ADDR_WIDTH]) &&
                     (wptr[ADDR_WIDTH-1:0] == rptr_w[ADDR_WIDTH-1:0]);
    assign wfull = wfull_int;
    assign waddr = wptr;

    wire winc_eff = winc && !wfull_int;

    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wptr <= {PTR_WIDTH{1'b0}};
            rptr_w <= {PTR_WIDTH{1'b0}};
            wdata_reg <= {DATA_WIDTH{1'b0}};
            wdata_valid <= 1'b0;
        end else begin
            if (winc_eff) begin
                mem[wptr[ADDR_WIDTH-1:0]] <= wdata;
                wptr <= wptr + 1'b1;
                wdata_reg <= wdata;
                wdata_valid <= 1'b1;
            end
            if (rptr_sync[SYNC_STAGES-1] != rptr_w) begin
                rptr_w <= rptr_sync[SYNC_STAGES-1];
            end
        end
    end

    // Read domain logic
    wire rempty_int = (rptr == wptr_r);
    assign rempty = rempty_int;
    assign raddr = rptr;

    wire rinc_eff = rinc && !rempty_int;

    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rptr <= {PTR_WIDTH{1'b0}};
            wptr_r <= {PTR_WIDTH{1'b0}};
            rdata_reg <= {DATA_WIDTH{1'b0}};
            rdata_valid <= 1'b0;
        end else begin
            if (rinc_eff) begin
                rdata_reg <= mem[rptr[ADDR_WIDTH-1:0]];
                rptr <= rptr + 1'b1;
                rdata_valid <= 1'b1;
            end
            if (wptr_sync[SYNC_STAGES-1] != wptr_r) begin
                wptr_r <= wptr_sync[SYNC_STAGES-1];
            end
        end
    end

    assign rdata = rdata_reg;

    // Synchronizer for wptr to read domain
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            for (int i = 0; i < SYNC_STAGES; i = i + 1)
                wptr_sync[i] <= {PTR_WIDTH{1'b0}};
        end else begin
            wptr_sync[0] <= wptr;
            for (int i = 1; i < SYNC_STAGES; i = i + 1)
                wptr_sync[i] <= wptr_sync[i-1];
        end
    end

    // Synchronizer for rptr to write domain
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            for (int i = 0; i < SYNC_STAGES; i = i + 1)
                rptr_sync[i] <= {PTR_WIDTH{1'b0}};
        end else begin
            rptr_sync[0] <= rptr;
            for (int i = 1; i < SYNC_STAGES; i = i + 1)
                rptr_sync[i] <= rptr_sync[i-1];
        end
    end

endmodule
