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

    // FIFO core signals
    reg [ASIZE-1:0] write_pointer;
    reg [ASIZE-1:0] read_pointer;
    reg [DSIZE-1:0] data_storage [0:(1<<ASIZE)-1];
    wire [DSIZE-1:0] write_data;
    wire write_enable;
    wire [DSIZE-1:0] read_data;
    wire read_enable;
    wire full_flag;
    wire empty_flag;
    wire awfull_flag;
    wire arempty_flag;

    // FIFO core instantiation
    fifo_core #(
        .DSIZE(DSIZE),
        .ASIZE(ASIZE),
        .FALLTHROUGH(FALLTHROUGH)
    ) fifo_core_inst (
        .wdata(write_data),
        .winc(write_enable),
        .wfull(wfull),
        .awfull(awfull),
        .rdata(read_data),
        .rinc(read_enable),
        .rempty(rempty),
        .arempty(arempty),
        .wclk(wclk),
        .wrst_n(wrst_n),
        .rclk(rclk),
        .rrst_n(rrst_n)
    );

    // Write domain signals
    wire [DSIZE-1:0] wdata_sync;
    wire winc_sync;
    wire wclk_sync;
    wire wrst_n_sync;

    // Write domain crossing instantiation
    wclk_domain_crossing #(
        .DSIZE(DSIZE),
        .ASIZE(ASIZE),
        .FALLTHROUGH(FALLTHROUGH)
    ) wclk_domain_crossing_inst (
        .write_data(wdata_sync),
        .write_enable(winc_sync),
        .full(full_flag),
        .awfull(awfull_flag),
        .write_clock(wclk),
        .write_reset(wrst_n)
    );

    // Read domain signals
    wire [DSIZE-1:0] rdata_sync;
    wire rinc_sync;
    wire rclk_sync;
    wire rrst_n_sync;

    // Read domain crossing instantiation
    rclk_domain_crossing #(
        .DSIZE(DSIZE),
        .ASIZE(ASIZE),
        .FALLTHROUGH(FALLTHROUGH)
    ) rclk_domain_crossing_inst (
        .read_data(rdata_sync),
        .read_enable(rinc_sync),
        .rempty(rempty_flag),
        .arempty(arempty_flag),
        .read_clock(rclk),
        .read_reset(rrst_n)
    );

    // FIFO core signal connections
    assign write_data = wdata_sync;
    assign write_enable = winc_sync;
    assign read_data = rdata_sync;
    assign read_enable = rinc_sync;

    // Write pointer logic
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            write_pointer <= 0;
        end else if (write_enable && !full_flag) begin
            write_pointer <= write_pointer + 1;
        end
    end

    // Read pointer logic
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            read_pointer <= 0;
        end else if (read_enable && !rempty_flag) begin
            read_pointer <= read_pointer + 1;
        end
    end

    // Full and empty flags
    assign full_flag = (write_pointer == read_pointer + (1<<ASIZE));
    assign empty_flag = (write_pointer == read_pointer);

    // Almost full and empty flags
    assign awfull_flag = (write_pointer == read_pointer + (1<<(ASIZE-1)));
    assign arempty_flag = (write_pointer == read_pointer + 1);

endmodule

module fifo_core
    #(
        parameter DSIZE = 8,
        parameter ASIZE = 4,
        parameter FALLTHROUGH = "TRUE"
    )(
        input  wire [DSIZE-1:0] wdata,
        input  wire             winc,
        output wire             wfull,
        output wire             awfull,
        input  wire [DSIZE-1:0] rdata,
        input  wire             rinc,
        output wire             rempty,
        output wire             arempty,
        input  wire             wclk,
        input  wire             wrst_n,
        input  wire             rclk,
        input  wire             rrst_n
    );

    reg [ASIZE-1:0] write_pointer;
    reg [ASIZE-1:0] read_pointer;
    reg [DSIZE-1:0] data_storage [0:(1<<ASIZE)-1];
    wire full_flag;
    wire empty_flag;
    wire awfull_flag;
    wire arempty_flag;

    assign wfull = full_flag;
    assign awfull = awfull_flag;
    assign rempty = empty_flag;
    assign arempty = arempty_flag;

    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            write_pointer <= 0;
        end else if (winc && !full_flag) begin
            data_storage[write_pointer] <= wdata;
            write_pointer <= write_pointer + 1;
        end
    end

    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            read_pointer <= 0;
        end else if (rinc && !empty_flag) begin
            read_pointer <= read_pointer + 1;
        end
    end

    assign full_flag = (write_pointer == read_pointer + (1<<ASIZE));
    assign empty_flag = (write_pointer == read_pointer);

    assign awfull_flag = (write_pointer == read_pointer + (1<<(ASIZE-1)));
    assign arempty_flag = (write_pointer == read_pointer + 1);

endmodule

module wclk_domain_crossing
    #(
        parameter DSIZE = 8,
        parameter ASIZE = 4,
        parameter FALLTHROUGH = "TRUE"
    )(
        output wire [DSIZE-1:0] write_data,
        output wire             write_enable,
        input  wire             full,
        output wire             awfull,
        input  wire             write_clock,
        input  wire             write_reset
    );

    reg [DSIZE-1:0] write_data_reg;
    reg write_enable_reg;
    reg full_reg;
    reg awfull_reg;

    always @(posedge write_clock or negedge write_reset) begin
        if (!write_reset) begin
            write_data_reg <= 0;
            write_enable_reg <= 0;
            full_reg <= 0;
            awfull_reg <= 0;
        end else begin
            write_data_reg <= write_data;
            write_enable_reg <= write_enable;
            full_reg <= full;
            awfull_reg <= awfull;
        end
    end

    assign write_data = write_data_reg;
    assign write_enable = write_enable_reg;
    assign full = full_reg;
    assign awfull = awfull_reg;

endmodule

module rclk_domain_crossing
    #(
        parameter DSIZE = 8,
        parameter ASIZE = 4,
        parameter FALLTHROUGH = "TRUE"
    )(
        input  wire [DSIZE-1:0] read_data,
        output wire             read_enable,
        input  wire             rempty,
        output wire             arempty,
        input  wire             read_clock,
        input  wire             read_reset
    );

    reg [DSIZE-1:0] read_data_reg;
    reg read_enable_reg;
    reg rempty_reg;
    reg arempty_reg;

    always @(posedge read_clock or negedge read_reset) begin
        if (!read_reset) begin
            read_data_reg <= 0;
            read_enable_reg <= 0;
            rempty_reg <= 0;
            arempty_reg <= 0;
        end else begin
            read_data_reg <= read_data;
            read_enable_reg <= read_enable;
            rempty_reg <= rempty;
            arempty_reg <= arempty;
        end
    end

    assign read_data = read_data_reg;
    assign read_enable = read_enable_reg;
    assign rempty = rempty_reg;
    assign arempty = arempty_reg;

endmodule
