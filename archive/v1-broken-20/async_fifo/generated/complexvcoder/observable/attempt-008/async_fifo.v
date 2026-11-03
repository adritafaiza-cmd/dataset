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
    reg [ASIZE-1:0] write_pointer;
    reg [ASIZE-1:0] read_pointer;
    reg [DSIZE-1:0] memory [0:(1<<ASIZE)-1];
    reg wfull_reg, awfull_reg, rempty_reg, arempty_reg;

    // Write pointer logic
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            write_pointer <= 0;
        end else if (winc && !wfull_reg) begin
            write_pointer <= write_pointer + 1;
        end
    end

    // Read pointer logic
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            read_pointer <= 0;
        end else if (rinc && !rempty_reg) begin
            read_pointer <= read_pointer + 1;
        end
    end

    // Memory logic
    always @(posedge wclk) begin
        if (winc && !wfull_reg) begin
            memory[write_pointer] <= wdata;
        end
    end

    // Full flag logic
    assign wfull_reg = (write_pointer == read_pointer) && !rempty_reg;
    assign awfull_reg = wfull_reg;

    // Empty flag logic
    assign rempty_reg = (write_pointer == read_pointer) && !wfull_reg;
    assign arempty_reg = rempty_reg;

    // Output logic
    assign wfull = wfull_reg;
    assign awfull = awfull_reg;
    assign rempty = rempty_reg;
    assign arempty = arempty_reg;
    assign rdata = memory[read_pointer];

endmodule
