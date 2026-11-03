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
    reg [DSIZE-1:0] mem [0:(2**ASIZE)-1];
    reg [ASIZE-1:0] wr_ptr, rd_ptr;
    reg [ASIZE-1:0] rd_ptr_gray, wr_ptr_gray;
    reg [ASIZE-1:0] wr_ptr_gray_sync, rd_ptr_gray_sync;
    wire [ASIZE-1:0] gray_to_bin_wr, gray_to_bin_rd;
    wire [ASIZE-1:0] gray_to_bin_wr_sync, gray_to_bin_rd_sync;
    reg [ASIZE:0] diff, diff_sync;
    reg wfull_raw, rempty_raw;
    reg [DSIZE-1:0] rdata_reg;
    reg winc_reg, rinc_reg;

    // Binary to Gray code conversion
    function [ASIZE-1:0] bin_to_gray;
        input [ASIZE-1:0] bin;
        bin_to_gray = bin ^ (bin >> 1);
    endfunction

    // Gray to Binary code conversion
    function [ASIZE-1:0] gray_to_bin;
        input [ASIZE-1:0] gray;
        reg [ASIZE-1:0] bin;
        integer i;
        bin = gray;
        for (i = ASIZE - 2; i >= 0; i = i - 1) begin
            bin[i] = bin[i+1] ^ gray[i];
        end
        gray_to_bin = bin;
    endfunction

    // Write domain logic
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wr_ptr <= 0;
            wr_ptr_gray <= 0;
            wr_ptr_gray_sync <= 0;
            mem <= '{default:0};
        end else begin
            if (winc && !wfull_raw) begin
                mem[wr_ptr] <= wdata;
                wr_ptr <= wr_ptr + 1;
            end
            wr_ptr_gray <= bin_to_gray(wr_ptr);
            wr_ptr_gray_sync <= rd_ptr_gray;
        end
    end

    // Read domain logic
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rd_ptr <= 0;
            rd_ptr_gray <= 0;
            rd_ptr_gray_sync <= 0;
            rdata_reg <= 0;
            rinc_reg <= 0;
            winc_reg <= 0;
        end else begin
            if (rinc && !rempty_raw) begin
                rdata_reg <= mem[rd_ptr];
                rd_ptr <= rd_ptr + 1;
            end
            rd_ptr_gray <= bin_to_gray(rd_ptr);
            rd_ptr_gray_sync <= wr_ptr_gray;
            rinc_reg <= rinc;
            winc_reg <= winc;
        end
    end

    // Gray code to binary conversion in read domain
    assign gray_to_bin_wr_sync = gray_to_bin(wr_ptr_gray_sync);
    assign gray_to_bin_rd_sync = gray_to_bin(rd_ptr_gray_sync);

    // Calculate difference
    assign diff = gray_to_bin_wr_sync - gray_to_bin_rd_sync;

    // Synchronize diff to read domain
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n)
            diff_sync <= 0;
        else
            diff_sync <= diff;
    end

    // Status flags
    assign wfull_raw = (diff_sync >= (2**ASIZE - 1));
    assign rempty_raw = (diff_sync == 0);
    assign wfull = wfull_raw;
    assign rempty = rempty_raw;
    assign awfull = (diff_sync >= (2**ASIZE - 2));
    assign arempty = (diff_sync <= 1);

    // Data output
    always @(posedge rclk) begin
        if (rrst_n) begin
            if (FALLTHROUGH == "TRUE") begin
                if (!rempty_raw)
                    rdata <= rdata_reg;
            end else begin
                if (rinc && !rempty_raw)
                    rdata <= rdata_reg;
            end
        end
    end

endmodule
