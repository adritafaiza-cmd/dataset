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
    reg  [ASIZE:0] write_pointer, read_pointer;
    reg  [ASIZE:0] write_pointer_gray, read_pointer_gray;
    reg  [ASIZE:0] write_pointer_sync, read_pointer_sync;
    reg  [DSIZE-1:0] read_data;
    wire [ASIZE:0] write_pointer_next, read_pointer_next;
    wire [ASIZE:0] write_pointer_gray_next, read_pointer_gray_next;
    wire write_full, write_almost_full;
    wire read_empty, read_almost_empty;

    // Gray code counter for write pointer
    gray_counter #(.SIZE(ASIZE+1)) write_gray_counter (
        .clk(wclk),
        .rst_n(wrst_n),
        .en(winc & ~wfull),
        .gray_out(write_pointer_gray),
        .bin_out(write_pointer_next)
    );

    // Gray code counter for read pointer
    gray_counter #(.SIZE(ASIZE+1)) read_gray_counter (
        .clk(rclk),
        .rst_n(rrst_n),
        .en(rinc & ~rempty),
        .gray_out(read_pointer_gray),
        .bin_out(read_pointer_next)
    );

    // Synchronized read pointer in write domain
    gray_counter_sync #(.SIZE(ASIZE+1)) read_gray_counter_sync (
        .clk(wclk),
        .rst_n(wrst_n),
        .gray_in(read_pointer_gray),
        .gray_out(read_pointer_sync)
    );

    // Synchronized write pointer in read domain
    gray_counter_sync #(.SIZE(ASIZE+1)) write_gray_counter_sync (
        .clk(rclk),
        .rst_n(rrst_n),
        .gray_in(write_pointer_gray),
        .gray_out(write_pointer_sync)
    );

    // Memory array for FIFO data storage
    memory #(.DSIZE(DSIZE), .ASIZE(ASIZE)) fifo_memory (
        .wclk(wclk),
        .wrst_n(wrst_n),
        .winc(winc & ~wfull),
        .waddr(write_pointer),
        .wdata(wdata),
        .rclk(rclk),
        .rrst_n(rrst_n),
        .raddr(read_pointer),
        .rdata(read_data)
    );

    // Write pointer update
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n)
            write_pointer <= 0;
        else if (winc & ~wfull)
            write_pointer <= write_pointer_next;
    end

    // Read pointer update
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n)
            read_pointer <= 0;
        else if (rinc & ~rempty)
            read_pointer <= read_pointer_next;
    end

    // Full and almost full flags
    assign write_full = (write_pointer_gray == {~read_pointer_sync[ASIZE], read_pointer_sync[ASIZE-1:0]});
    assign write_almost_full = (write_pointer_gray == {read_pointer_sync[ASIZE], ~read_pointer_sync[ASIZE-1:0]});

    // Empty and almost empty flags
    assign read_empty = (read_pointer_gray == {~write_pointer_sync[ASIZE], write_pointer_sync[ASIZE-1:0]});
    assign read_almost_empty = (read_pointer_gray == {write_pointer_sync[ASIZE], ~write_pointer_sync[ASIZE-1:0]});

    // Outputs
    assign wfull = write_full;
    assign awfull = write_almost_full;
    assign rdata = read_data;
    assign rempty = read_empty;
    assign arempty = read_almost_empty;

    // First-word fall-through handling
    reg fallthrough_flag;
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n)
            fallthrough_flag <= 0;
        else if (rinc & ~rempty)
            fallthrough_flag <= 1;
        else if (rempty)
            fallthrough_flag <= 0;
    end

    assign rempty = read_empty & (!FALLTHROUGH || fallthrough_flag);

endmodule

// Gray code counter module
module gray_counter
    #(
        parameter SIZE = 4
    )(
        input  wire clk,
        input  wire rst_n,
        input  wire en,
        output reg  [SIZE-1:0] gray_out,
        output reg  [SIZE-1:0] bin_out
    );

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            gray_out <= 0;
            bin_out <= 0;
        end else if (en) begin
            bin_out <= bin_out + 1;
            gray_out <= (bin_out + 1) ^ (bin_out + 1) >> 1;
        end
    end

endmodule

// Gray code synchronizer module
module gray_counter_sync
    #(
        parameter SIZE = 4
    )(
        input  wire clk,
        input  wire rst_n,
        input  wire [SIZE-1:0] gray_in,
        output reg  [SIZE-1:0] gray_out
    );

    reg [SIZE-1:0] sync_reg1, sync_reg2;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sync_reg1 <= 0;
            sync_reg2 <= 0;
            gray_out <= 0;
        end else begin
            sync_reg1 <= gray_in;
            sync_reg2 <= sync_reg1;
            gray_out <= sync_reg2;
        end
    end

endmodule

// Memory module
module memory
    #(
        parameter DSIZE = 8,
        parameter ASIZE = 4
    )(
        input  wire wclk,
        input  wire wrst_n,
        input  wire winc,
        input  wire [ASIZE:0] waddr,
        input  wire [DSIZE-1:0] wdata,
        input  wire rclk,
        input  wire rrst_n,
        input  wire [ASIZE:0] raddr,
        output wire [DSIZE-1:0] rdata
    );

    reg [DSIZE-1:0] mem [0:(1<<ASIZE)-1];
    reg [DSIZE-1:0] rdata_reg;

    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            mem <= '{default: 0};
        end else if (winc) begin
            mem[waddr[ASIZE-1:0]] <= wdata;
        end
    end

    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n)
            rdata_reg <= 0;
        else
            rdata_reg <= mem[raddr[ASIZE-1:0]];
    end

    assign rdata = rdata_reg;

endmodule
