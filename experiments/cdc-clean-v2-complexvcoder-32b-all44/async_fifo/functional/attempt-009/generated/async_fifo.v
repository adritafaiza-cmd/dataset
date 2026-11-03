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
    wire [ASIZE:0] wptr_bin, wptr_bin_next;
    wire [ASIZE:0] rptr_bin, rptr_bin_next;
    wire [ASIZE:0] wptr_gray, wptr_gray_next;
    wire [ASIZE:0] rptr_gray, rptr_gray_next;
    wire [ASIZE:0] wptr_gray_sync_rclk, wptr_gray_sync2_rclk, wptr_gray_sync3_rclk, wptr_gray_sync4_rclk, wptr_gray_sync5_rclk;
    wire [ASIZE:0] rptr_gray_sync_wclk, rptr_gray_sync2_wclk, rptr_gray_sync3_wclk, rptr_gray_sync4_wclk, rptr_gray_sync5_wclk;
    wire wfull_int, rempty_int;
    wire wfull_sync_rclk, rempty_sync_wclk;
    reg [DSIZE-1:0] mem [0:(1<<ASIZE)-1];
    reg [DSIZE-1:0] rdata_int;
    reg [DSIZE-1:0] rdata_reg;
    reg rempty_reg;

    // Gray code conversion
    function [ASIZE:0] bin2gray;
        input [ASIZE:0] bin;
        bin2gray = bin ^ (bin >> 1);
    endfunction

    // Binary code conversion
    function [ASIZE:0] gray2bin;
        input [ASIZE:0] gray;
        integer i;
        reg [ASIZE:0] bin;
        bin = gray;
        for (i = ASIZE; i > 0; i = i - 1) begin
            bin[i-1] = bin[i] ^ bin[i-1];
        end
        gray2bin = bin;
    endfunction

    // Write domain logic
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wptr_bin <= 0;
            wptr_gray <= 0;
            wfull_int <= 0;
        end else if (winc && !wfull_int) begin
            wptr_bin_next = wptr_bin + 1;
            wptr_gray_next = bin2gray(wptr_bin_next);
            wptr_bin <= wptr_bin_next;
            wptr_gray <= wptr_gray_next;
            mem[wptr_bin[ASIZE-1:0]] <= wdata;
        end
    end

    // Read domain logic
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rptr_bin <= 0;
            rptr_gray <= 0;
            rempty_int <= 1;
            rdata_int <= 0;
            rdata_reg <= 0;
            rempty_reg <= 1;
        end else if (rinc && !rempty_int) begin
            rptr_bin_next = rptr_bin + 1;
            rptr_gray_next = bin2gray(rptr_bin_next);
            rptr_bin <= rptr_bin_next;
            rptr_gray <= rptr_gray_next;
            rdata_int <= mem[rptr_bin[ASIZE-1:0]];
        end
        if (rempty_int) begin
            rdata_reg <= 0;
        end else begin
            rdata_reg <= rdata_int;
        end
        rempty_reg <= rempty_int;
    end

    // Synchronization of pointers
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            wptr_gray_sync_rclk <= 0;
            wptr_gray_sync2_rclk <= 0;
            wptr_gray_sync3_rclk <= 0;
            wptr_gray_sync4_rclk <= 0;
            wptr_gray_sync5_rclk <= 0;
        end else begin
            wptr_gray_sync_rclk <= wptr_gray;
            wptr_gray_sync2_rclk <= wptr_gray_sync_rclk;
            wptr_gray_sync3_rclk <= wptr_gray_sync2_rclk;
            wptr_gray_sync4_rclk <= wptr_gray_sync3_rclk;
            wptr_gray_sync5_rclk <= wptr_gray_sync4_rclk;
        end
    end

    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            rptr_gray_sync_wclk <= 0;
            rptr_gray_sync2_wclk <= 0;
            rptr_gray_sync3_wclk <= 0;
            rptr_gray_sync4_wclk <= 0;
            rptr_gray_sync5_wclk <= 0;
        end else begin
            rptr_gray_sync_wclk <= rptr_gray;
            rptr_gray_sync2_wclk <= rptr_gray_sync_wclk;
            rptr_gray_sync3_wclk <= rptr_gray_sync2_wclk;
            rptr_gray_sync4_wclk <= rptr_gray_sync3_wclk;
            rptr_gray_sync5_wclk <= rptr_gray_sync4_wclk;
        end
    end

    // Full and empty flags
    assign wfull_int = (wptr_gray_sync_rclk == bin2gray(gray2bin(rptr_gray_sync_wclk) + 1));
    assign rempty_int = (wptr_gray_sync5_rclk == rptr_gray_sync5_wclk);
    assign awfull = (wptr_gray_sync_rclk == bin2gray(gray2bin(rptr_gray_sync2_wclk) + 1));
    assign arempty = (wptr_gray_sync4_rclk == rptr_gray_sync4_wclk);

    // Synchronization of full and empty flags
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            wfull_sync_rclk <= 0;
        end else begin
            wfull_sync_rclk <= wfull_int;
        end
    end

    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            rempty_sync_wclk <= 0;
        end else begin
            rempty_sync_wclk <= rempty_int;
        end
    end

    // Output assignments
    assign wfull = wfull_sync_rclk;
    assign rempty = rempty_sync_wclk;
    assign rdata = (FALLTHROUGH == "TRUE" && rempty_reg && !rempty_int) ? rdata_int : rdata_reg;

endmodule
