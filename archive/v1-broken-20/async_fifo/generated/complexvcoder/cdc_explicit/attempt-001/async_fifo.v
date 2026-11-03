module async_fifo
    #(
        parameter DSIZE = 8,
        parameter ASIZE = 4,
        parameter FALLTHROUGH = "TRUE"
    )(
        input  wire             wclk,
        input  wire             wrst_n,
        input  wire             winc,
        input  wire [DSIZE-1:0] wdata,
        output wire             wfull,
        output wire             awfull,
        input  wire             rclk,
        input  wire             rrst_n,
        input  wire             rinc,
        output wire [DSIZE-1:0] rdata,
        output wire             rempty,
        output wire             arempty
    );

    // Internal signals
    reg [ASIZE:0] wr_ptr;
    reg [ASIZE:0] rd_ptr;
    reg [ASIZE:0] wr_ptr_sync;
    reg [ASIZE:0] rd_ptr_sync;
    reg [DSIZE-1:0] fifo [0:(1<<ASIZE)-1];
    reg wfull_int;
    reg awfull_int;
    reg rempty_int;
    reg arempty_int;

    // Write pointer logic
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wr_ptr <= 0;
        end else if (winc && !wfull_int) begin
            wr_ptr <= wr_ptr + 1;
        end
    end

    // Read pointer logic
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rd_ptr <= 0;
        end else if (rinc && !rempty_int) begin
            rd_ptr <= rd_ptr + 1;
        end
    end

    // Synchronize write and read pointers
    cdc_sync #(
        .WIDTH(ASIZE + 1)
    ) cdc_sync_inst (
        .wclk(wclk),
        .wrst_n(wrst_n),
        .rclk(rclk),
        .rrst_n(rrst_n),
        .winc(winc),
        .wdata(wdata),
        .rinc(rinc),
        .wfull(wfull_int),
        .awfull(awfull_int),
        .rempty(rempty_int),
        .arempty(arempty_int),
        .winc_sync(wr_ptr_sync),
        .wdata_sync(wdata),
        .rinc_sync(rd_ptr_sync)
    );

    // FIFO full and almost full logic
    assign wfull_int = (wr_ptr_sync == rd_ptr_sync + (1<<ASIZE));
    assign awfull_int = (wr_ptr_sync == rd_ptr_sync + (1<<(ASIZE-1)));

    // FIFO empty and almost empty logic
    assign rempty_int = (wr_ptr_sync == rd_ptr_sync);
    assign arempty_int = (wr_ptr_sync == rd_ptr_sync + 1);

    // FIFO data output
    assign rdata = (FALLTHROUGH == "TRUE") ? fifo[rd_ptr] : (rempty_int ? 0 : fifo[rd_ptr]);

    // Output ports
    assign wfull = wfull_int;
    assign awfull = awfull_int;
    assign rdata = rdata;
    assign rempty = rempty_int;
    assign arempty = arempty_int;

endmodule

module cdc_sync
    #(
        .WIDTH(1)
    ) (
        input  wire             wclk,
        input  wire             wrst_n,
        input  wire             rclk,
        input  wire             rrst_n,
        input  wire             winc,
        input  wire [7:0]         wdata,
        input  wire             rinc,
        input  wire             wfull,
        input  wire             awfull,
        input  wire             rempty,
        input  wire             arempty,
        output reg            winc_sync,
        output reg [7:0]         wdata_sync,
        output reg            rinc_sync
    );

    reg [WIDTH-1:0] winc_sync_reg;
    reg [WIDTH-1:0] rinc_sync_reg;

    // Write increment synchronization
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            winc_sync_reg <= 0;
        end else begin
            winc_sync_reg <= winc;
        end
    end

    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            winc_sync <= 0;
        end else begin
            winc_sync <= winc_sync_reg;
        end
    end

    // Write data synchronization
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wdata_sync_reg <= 0;
        end else begin
            wdata_sync_reg <= wdata;
        end
    end

    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            wdata_sync <= 0;
        end else begin
            wdata_sync <= wdata_sync_reg;
        end
    end

    // Read increment synchronization
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rinc_sync_reg <= 0;
        end else begin
            rinc_sync_reg <= rinc;
        end
    end

    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            rinc_sync <= 0;
        end else begin
            rinc_sync <= rinc_sync_reg;
        end
    end

endmodule
