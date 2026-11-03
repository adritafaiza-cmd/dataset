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

    localparam FIFO_SIZE = 2**ASIZE;

    reg [ASIZE:0] wrptr;
    reg [ASIZE:0] rdptr;
    reg [DSIZE-1:0] fifo [0:FIFO_SIZE-1];

    wire wfull_int;
    wire wempty_int;
    wire rfull_int;
    wire rempty_int;

    assign wfull = wfull_int;
    assign awfull = (wfull_int && (wrptr == rdptr - 1));
    assign rempty = rempty_int;
    assign arempty = (rempty_int && (wrptr == rdptr));

    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wrptr <= 0;
        end else begin
            if (winc && !wfull_int) begin
                fifo[wrptr] <= wdata;
                wrptr <= wrptr + 1;
            end
        end
    end

    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rdptr <= 0;
        end else begin
            if (rinc && !rempty_int) begin
                rdptr <= rdptr + 1;
            end
        end
    end

    assign wfull_int = (wrptr == rdptr - 1);
    assign rempty_int = (wrptr == rdptr);

    always @(posedge rclk) begin
        if (!rrst_n) begin
            rdata <= 0;
        end else begin
            if (rinc && !rempty_int) begin
                rdata <= fifo[rdptr];
            end
        end
    end

endmodule
