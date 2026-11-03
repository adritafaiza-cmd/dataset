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

    // Internal signals
    reg [DATA_WIDTH-1:0] mem [0:(1<<ADDR_WIDTH)-1];
    reg [ADDR_WIDTH:0] wptr;
    reg [ADDR_WIDTH:0] rptr;
    reg [ADDR_WIDTH:0] wfull_flag;
    reg [ADDR_WIDTH:0] rempty_flag;

    // Synchronization flip-flops
    reg [SYNC_STAGES-1:0] wclk_sync [0:SYNC_STAGES-1];
    reg [SYNC_STAGES-1:0] wrst_n_sync [0:SYNC_STAGES-1];
    reg [SYNC_STAGES-1:0] winc_sync [0:SYNC_STAGES-1];
    reg [SYNC_STAGES-1:0] wdata_sync [0:SYNC_STAGES-1];
    reg [SYNC_STAGES-1:0] rclk_sync [0:SYNC_STAGES-1];
    reg [SYNC_STAGES-1:0] rrst_n_sync [0:SYNC_STAGES-1];
    reg [SYNC_STAGES-1:0] rinc_sync [0:SYNC_STAGES-1];

    // Synchronizer for write domain
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wclk_sync <= {SYNC_STAGES{1'b0}};
        end else begin
            wclk_sync <= {wclk_sync[SYNC_STAGES-2:0], wclk};
        end
    end

    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wrst_n_sync <= {SYNC_STAGES{1'b0}};
        end else begin
            wrst_n_sync <= {wrst_n_sync[SYNC_STAGES-2:0], wrst_n};
        end
    end

    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            winc_sync <= {SYNC_STAGES{1'b0}};
        end else begin
            winc_sync <= {winc_sync[SYNC_STAGES-2:0], winc};
        end
    end

    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wdata_sync <= {SYNC_STAGES{1'b0}};
        end else begin
            wdata_sync <= {wdata_sync[SYNC_STAGES-2:0], wdata};
        end
    end

    // Synchronizer for read domain
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rclk_sync <= {SYNC_STAGES{1'b0}};
        end else begin
            rclk_sync <= {rclk_sync[SYNC_STAGES-2:0], rclk};
        end
    end

    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rrst_n_sync <= {SYNC_STAGES{1'b0}};
        end else begin
            rrst_n_sync <= {rrst_n_sync[SYNC_STAGES-2:0], rrst_n};
        end
    end

    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rinc_sync <= {SYNC_STAGES{1'b0}};
        end else begin
            rinc_sync <= {rinc_sync[SYNC_STAGES-2:0], rinc};
        end
    end

    // Write logic
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wptr <= 0;
            wfull_flag <= 0;
        end else begin
            if (winc && !wfull_flag && (wptr != rptr)) begin
                mem[wptr] <= wdata_sync[SYNC_STAGES-1];
                wptr <= wptr + 1;
                if (wptr == (1<<ADDR_WIDTH)) begin
                    wptr <= 0;
                end
            end
            if (wptr == ((rptr + 1) & ((1<<ADDR_WIDTH)-1))) begin
                wfull_flag <= 1;
            end else begin
                wfull_flag <= 0;
            end
        end
    end

    // Read logic
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rptr <= 0;
            rempty_flag <= 1;
        end else begin
            if (rinc && !rempty_flag) begin
                rdata <= mem[rptr];
                rptr <= rptr + 1;
                if (rptr == (1<<ADDR_WIDTH)) begin
                    rptr <= 0;
                end
            end
            if (wptr == rptr) begin
                rempty_flag <= 1;
            end else begin
                rempty_flag <= 0;
            end
        end
    end

    // Output assignments
    assign waddr = wptr;
    assign raddr = rptr;
    assign wfull = wfull_flag;
    assign rempty = rempty_flag;

endmodule
