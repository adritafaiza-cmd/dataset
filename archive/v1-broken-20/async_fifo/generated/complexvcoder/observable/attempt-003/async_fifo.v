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

    wire [ASIZE-1:0] write_pointer;
    wire [ASIZE-1:0] read_pointer;
    reg  [DSIZE-1:0] data_memory [0:(2**ASIZE)-1];
    reg  wfull_reg;
    reg  awfull_reg;
    reg  rempty_reg;
    reg  arempty_reg;
    wire winc_sync;
    wire awfull_sync;
    wire [DSIZE-1:0] wdata_sync;
    wire rinc_sync;
    wire [DSIZE-1:0] rdata_sync;
    wire rempty_sync;
    wire arempty_sync;

    cross_domain_sync #(.DSIZE(DSIZE), .ASIZE(ASIZE)) cross_domain_sync_inst (
        .wclk(wclk),
        .wrst_n(wrst_n),
        .winc(winc),
        .wdata(wdata),
        .rclk(rclk),
        .rrst_n(rrst_n),
        .rinc(rinc),
        .winc_sync(winc_sync),
        .wdata_sync(wdata_sync),
        .rinc_sync(rinc_sync),
        .rdata_sync(rdata_sync),
        .wfull_sync(wfull),
        .awfull_sync(awfull),
        .rempty_sync(rempty_sync),
        .arempty_sync(arempty_sync)
    );

    fifo_state_machine #(.DSIZE(DSIZE), .ASIZE(ASIZE), .FALLTHROUGH(FALLTHROUGH)) fifo_state_machine_inst (
        .wclk(wclk),
        .wrst_n(wrst_n),
        .winc(winc_sync),
        .wdata(wdata_sync),
        .rclk(rclk),
        .rrst_n(rrst_n),
        .rinc(rinc_sync),
        .write_pointer(write_pointer),
        .read_pointer(read_pointer),
        .data_memory(data_memory),
        .wfull(wfull_reg),
        .awfull(awfull_reg),
        .rempty(rempty_reg),
        .arempty(arempty_reg)
    );

    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wfull_reg <= 1'b0;
            awfull_reg <= 1'b0;
        end else begin
            wfull_reg <= wfull;
            awfull_reg <= awfull;
        end
    end

    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rempty_reg <= 1'b1;
            arempty_reg <= 1'b1;
        end else begin
            rempty_reg <= rempty;
            arempty_reg <= arempty;
        end
    end

    assign wfull = wfull_reg;
    assign awfull = awfull_reg;
    assign rempty = rempty_reg;
    assign arempty = arempty_reg;

endmodule

module cross_domain_sync
    #(
        parameter DSIZE = 8,
        parameter ASIZE = 4
    )(
        input  wire             wclk,
        input  wire             wrst_n,
        input  wire             winc,
        input  wire [DSIZE-1:0] wdata,
        input  wire             rclk,
        input  wire             rrst_n,
        input  wire             rinc,
        output reg              winc_sync,
        output reg [DSIZE-1:0] wdata_sync,
        output reg              rinc_sync,
        output reg [DSIZE-1:0] rdata_sync,
        output reg              wfull_sync,
        output reg              awfull_sync,
        output reg              rempty_sync,
        output reg              arempty_sync
    );

    reg winc_sync_ff;
    reg [DSIZE-1:0] wdata_sync_ff;
    reg rinc_sync_ff;
    reg [DSIZE-1:0] rdata_sync_ff;
    reg wfull_sync_ff;
    reg awfull_sync_ff;
    reg rempty_sync_ff;
    reg arempty_sync_ff;

    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            winc_sync_ff <= 1'b0;
            wdata_sync_ff <= 0;
            wfull_sync_ff <= 1'b0;
            awfull_sync_ff <= 1'b0;
        end else begin
            winc_sync_ff <= winc;
            wdata_sync_ff <= wdata;
            wfull_sync_ff <= wfull_sync;
            awfull_sync_ff <= awfull_sync;
        end
    end

    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rinc_sync_ff <= 1'b0;
            rdata_sync_ff <= 0;
            rempty_sync_ff <= 1'b1;
            arempty_sync_ff <= 1'b1;
        end else begin
            rinc_sync_ff <= rinc_sync;
            rdata_sync_ff <= rdata_sync;
            rempty_sync_ff <= rempty_sync;
            arempty_sync_ff <= arempty_sync;
        end
    end

    assign winc_sync = winc_sync_ff;
    assign wdata_sync = wdata_sync_ff;
    assign rinc_sync = rinc_sync_ff;
    assign rdata_sync = rdata_sync_ff;
    assign wfull_sync = wfull_sync_ff;
    assign awfull_sync = awfull_sync_ff;
    assign rempty_sync = rempty_sync_ff;
    assign arempty_sync = arempty_sync_ff;

endmodule

module fifo_state_machine
    #(
        parameter DSIZE = 8,
        parameter ASIZE = 4,
        parameter FALLTHROUGH = "TRUE"
    )(
        input  wire             wclk,
        input  wire             wrst_n,
        input  wire             winc,
        input  wire [DSIZE-1:0] wdata,
        input  wire             rclk,
        input  wire             rrst_n,
        input  wire             rinc,
        output reg [ASIZE-1:0] write_pointer,
        output reg [ASIZE-1:0] read_pointer,
        output reg [DSIZE-1:0] data_memory [0:(2**ASIZE)-1],
        output reg              wfull,
        output reg              awfull,
        output reg              rempty,
        output reg              arempty
    );

    reg [ASIZE-1:0] write_pointer_ff;
    reg [ASIZE-1:0] read_pointer_ff;
    reg [DSIZE-1:0] data_memory_ff [0:(2**ASIZE)-1];
    reg wfull_ff;
    reg awfull_ff;
    reg rempty_ff;
    reg arempty_ff;

    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            write_pointer_ff <= 0;
            data_memory_ff <= 0;
            wfull_ff <= 1'b0;
            awfull_ff <= 1'b0;
        end else begin
            write_pointer_ff <= write_pointer;
            data_memory_ff <= data_memory;
            wfull_ff <= wfull;
            awfull_ff <= awfull;
        end
    end

    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            read_pointer_ff <= 0;
            rempty_ff <= 1'b1;
            arempty_ff <= 1'b1;
        end else begin
            read_pointer_ff <= read_pointer;
            rempty_ff <= rempty;
            arempty_ff <= arempty;
        end
    end

    assign write_pointer = write_pointer_ff;
    assign read_pointer = read_pointer_ff;
    assign data_memory = data_memory_ff;
    assign wfull = wfull_ff;
    assign awfull = awfull_ff;
    assign rempty = rempty_ff;
    assign arempty = arempty_ff;

endmodule
