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
    wire [ASIZE-1:0] write_pointer;
    wire [ASIZE-1:0] read_pointer;
    wire [DSIZE-1:0] write_data;
    wire [DSIZE-1:0] read_data;
    wire full;
    wire empty;

    // FIFO Controller
    fifo_controller #(.DSIZE(DSIZE), .ASIZE(ASIZE), .FALLTHROUGH(FALLTHROUGH)) controller (
        .clk(wclk),
        .rst_n(wrst_n),
        .winc(winc),
        .rclk(rclk),
        .rrst_n(rrst_n),
        .rinc(rinc),
        .wfull(wfull),
        .awfull(awfull),
        .rempty(rempty),
        .arempty(arempty),
        .write_pointer(write_pointer),
        .read_pointer(read_pointer),
        .write_data(write_data),
        .read_data(read_data),
        .full(full),
        .empty(empty)
    );

    // FIFO Memory
    fifo_memory #(.DSIZE(DSIZE), .ASIZE(ASIZE)) memory (
        .write_address(write_pointer),
        .write_data(write_data),
        .read_address(read_pointer),
        .read_data(read_data)
    );

endmodule

// FIFO Controller
module fifo_controller
    #(
        parameter DSIZE = 8,
        parameter ASIZE = 4,
        parameter FALLTHROUGH = "TRUE"
    )(
        input  wire             clk,
        input  wire             rst_n,
        input  wire             winc,
        input  wire             rclk,
        input  wire             rrst_n,
        input  wire             rinc,
        output wire             wfull,
        output wire             awfull,
        output wire             rempty,
        output wire             arempty,
        output reg [ASIZE-1:0]   write_pointer,
        output reg [ASIZE-1:0]   read_pointer,
        output reg [DSIZE-1:0]   write_data,
        input  wire [DSIZE-1:0]   read_data,
        output reg              full,
        output reg              empty
    );

    // Internal signals
    reg [ASIZE-1:0] next_write_pointer;
    reg [ASIZE-1:0] next_read_pointer;
    reg [DSIZE-1:0] next_write_data;
    reg next_full;
    reg next_empty;

    // Write logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            write_pointer <= 0;
            write_data <= 0;
            full <= 0;
        end else if (winc && !full) begin
            next_write_pointer <= write_pointer + 1;
            next_write_data <= wdata;
            next_full <= (next_write_pointer == read_pointer);
        end else begin
            next_write_pointer <= write_pointer;
            next_write_data <= write_data;
            next_full <= full;
        end
    end

    // Read logic
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            read_pointer <= 0;
            rempty <= 1;
        end else if (rinc && !rempty) begin
            next_read_pointer <= read_pointer + 1;
            next_rempty <= (next_read_pointer == write_pointer);
        end else begin
            next_read_pointer <= read_pointer;
            next_rempty <= rempty;
        end
    end

    // Assignments
    assign wfull = next_full;
    assign awfull = (next_full && FALLTHROUGH == "TRUE");
    assign rempty = next_rempty;
    assign arempty = (next_rempty && FALLTHROUGH == "TRUE");

    // Write pointer assignment
    always @(posedge clk) begin
        write_pointer <= next_write_pointer;
    end

    // Read pointer assignment
    always @(posedge rclk) begin
        read_pointer <= next_read_pointer;
    end

    // Write data assignment
    always @(posedge clk) begin
        write_data <= next_write_data;
    end

    // Full flag assignment
    always @(posedge clk) begin
        full <= next_full;
    end

    // Empty flag assignment
    always @(posedge rclk) begin
        rempty <= next_rempty;
    end

endmodule

// FIFO Memory
module fifo_memory
    #(
        parameter DSIZE = 8,
        parameter ASIZE = 4
    )(
        input  wire [ASIZE-1:0] write_address,
        input  wire [DSIZE-1:0] write_data,
        input  wire [ASIZE-1:0] read_address,
        output wire [DSIZE-1:0] read_data
    );

    // Internal memory
    reg [DSIZE-1:0] mem [0:2**ASIZE-1];

    // Write operation
    always @(posedge write_address) begin
        mem[write_address] <= write_data;
    end

    // Read operation
    assign read_data = mem[read_address];

endmodule
