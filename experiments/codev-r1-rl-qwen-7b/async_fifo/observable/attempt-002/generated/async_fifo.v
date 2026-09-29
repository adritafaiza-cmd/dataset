module async_fifo #(
    parameter DSIZE = 8,
    parameter ASIZE = 4,
    parameter FALLTHROUGH = "TRUE"
) (
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

    // Memory array
    reg [DSIZE-1:0] mem [0:(1 << ASIZE)-1];

    // Pointers
    reg [ASIZE:0] wptr, rptr;

    // Gray code pointers
    wire [ASIZE:0] wgray, rgray;
    assign wgray = (wptr >> 1) ^ wptr;
    assign rgray = (rptr >> 1) ^ rptr;

    // Synchronization registers
    reg [ASIZE:0] rwrst_rdptr1, rwrst_rdptr2; // Read pointer synchronized to write clock
    reg [ASIZE:0] rrrst_wptr1, rrrst_wptr2;   // Write pointer synchronized to read clock

    // Synchronization processes
    // Read pointer synchronization to write clock domain
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            rwrst_rdptr1 <= 0;
            rwrst_rdptr2 <= 0;
        end else begin
            rwrst_rdptr1 <= rgray;
            rwrst_rdptr2 <= rwrst_rdptr1;
        end
    end

    // Write pointer synchronization to read clock domain
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rrrst_wptr1 <= 0;
            rrrst_wptr2 <= 0;
        end else begin
            rrrst_wptr1 <= wgray;
            rrrst_wptr2 <= rrrst_wptr1;
        end
    end

    // Full and empty conditions
    // Full condition in write domain
    wire wfull_val;
    assign wfull_val = ( (wgray == { ~rwrst_rdptr2[ASIZE:ASIZE-1], rwrst_rdptr2[ASIZE-2:0] }) );

    // Empty condition in read domain
    wire rempty_val;
    assign rempty_val = ( rgray == rrrst_wptr2 );

    // Almost full and almost empty
    // Convert synchronized gray to binary
    function [ASIZE:0] gray2bin;
        input [ASIZE:0] gray;
        reg [ASIZE:0] bin;
        integer i;
        begin
            bin[ASIZE] = gray[ASIZE];
            for (i = ASIZE-1; i >=0; i=i-1)
                bin[i] = bin[i+1] ^ gray[i];
            gray2bin = bin;
        end
    endfunction

    wire [ASIZE:0] wptr_sync = gray2bin(rrrst_wptr2);
    wire [ASIZE:0] rptr_sync = gray2bin(rwrst_rdptr2);

    // Used words in write domain
    wire [ASIZE:0] usedw = wptr - rptr_sync;
    assign awfull = (usedw >= ( (1 << ASIZE) -1 ));

    // Used words in read domain
    wire [ASIZE:0] usedr = rptr - wptr_sync;
    assign arempty = (usedr >= 1);

    // Assign outputs
    assign wfull = wfull_val;
    assign rempty = rempty_val;

    // Write logic
    generate
        if (FALLTHROUGH == "TRUE") begin
            assign winc_allow = winc;
        end else begin
            assign winc_allow = winc && !wfull_val;
        end
    endgenerate

    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wptr <= 0;
        end else if (winc_allow) begin
            wptr <= wptr + 1;
            mem[wptr[ASIZE-1:0]] <= wdata;
        end
    end

    // Read logic
    generate
        if (FALLTHROUGH == "TRUE") begin
            assign rinc_allow = rinc;
        end else begin
            assign rinc_allow = rinc && !rempty_val;
        end
    endgenerate

    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rptr <= 0;
        end else if (rinc_allow) begin
            rptr <= rptr + 1;
        end
    end

    // Read data
    assign rdata = mem[rptr[ASIZE-1:0]];

endmodule
