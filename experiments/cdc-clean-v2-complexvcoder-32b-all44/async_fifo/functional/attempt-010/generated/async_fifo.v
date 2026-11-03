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
    reg [ASIZE-1:0] write_ptr;
    reg [ASIZE-1:0] read_ptr;
    reg [ASIZE-1:0] write_ptr_gray;
    reg [ASIZE-1:0] read_ptr_gray;
    reg [ASIZE-1:0] gray_sync_wr;
    reg [ASIZE-1:0] gray_sync_rd;
    reg [ASIZE-1:0] read_ptr_sync;
    reg [ASIZE-1:0] write_ptr_sync;
    reg [DSIZE-1:0] mem [0:(1<<ASIZE)-1];
    reg [ASIZE-1:0] read_ptr_next;
    reg [ASIZE-1:0] write_ptr_next;
    reg             wfull_gray;
    reg             wfull_gray_sync;
    reg             rempty_gray;
    reg             rempty_gray_sync;
    reg             wfull_gray_sync2;
    reg             rempty_gray_sync2;
    reg             wfull_gray_sync3;
    reg             rempty_gray_sync3;
    reg             wfull_gray_sync4;
    reg             rempty_gray_sync4;
    reg             wfull_gray_sync5;
    reg             rempty_gray_sync5;
    reg             wfull_gray_sync6;
    reg             rempty_gray_sync6;
    reg             wfull_gray_sync7;
    reg             rempty_gray_sync7;
    reg             wfull_gray_sync8;
    reg             rempty_gray_sync8;
    reg             wfull_gray_sync9;
    reg             rempty_gray_sync9;
    reg             wfull_gray_sync10;
    reg             rempty_gray_sync10;
    reg             wfull_gray_sync11;
    reg             rempty_gray_sync11;
    reg             wfull_gray_sync12;
    reg             rempty_gray_sync12;
    reg             wfull_gray_sync13;
    reg             rempty_gray_sync13;
    reg             wfull_gray_sync14;
    reg             rempty_gray_sync14;
    reg             wfull_gray_sync15;
    reg             rempty_gray_sync15;

    // Binary to Gray converter
    function [ASIZE-1:0] binary_to_gray;
        input [ASIZE-1:0] bin;
        binary_to_gray = bin ^ (bin >> 1);
    endfunction

    // Gray to Binary converter
    function [ASIZE-1:0] gray_to_binary;
        input [ASIZE-1:0] gray;
        integer i;
        reg [ASIZE-1:0] bin;
        bin = gray;
        for (i = ASIZE-2; i >= 0; i = i - 1) begin
            bin[i] = bin[i+1] ^ gray[i];
        end
        gray_to_binary = bin;
    endfunction

    // Write domain logic
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            write_ptr <= 0;
            gray_sync_wr <= 0;
        end else begin
            if (winc && !wfull_gray_sync) begin
                write_ptr_next <= write_ptr + 1;
            end
            write_ptr <= write_ptr_next;
            write_ptr_gray <= binary_to_gray(write_ptr);
            gray_sync_wr <= write_ptr_gray;
        end
    end

    // Read domain logic
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            read_ptr <= 0;
            gray_sync_rd <= 0;
        end else begin
            if (rinc && !rempty_gray_sync) begin
                read_ptr_next <= read_ptr + 1;
            end
            read_ptr <= read_ptr_next;
            read_ptr_gray <= binary_to_gray(read_ptr);
            gray_sync_rd <= read_ptr_gray;
        end
    end

    // Synchronizers
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            gray_sync_wr_sync <= 0;
        end else begin
            gray_sync_wr_sync <= gray_sync_wr;
        end
    end

    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            gray_sync_rd_sync <= 0;
        end else begin
            gray_sync_rd_sync <= gray_sync_rd;
        end
    end

    // Convert synchronized gray codes to binary
    always @(*) begin
        write_ptr_sync = gray_to_binary(gray_sync_wr_sync);
        read_ptr_sync = gray_to_binary(gray_sync_rd_sync);
    end

    // Determine wfull_gray and rempty_gray
    always @(*) begin
        wfull_gray = (write_ptr_sync + 1) == read_ptr_sync;
        rempty_gray = write_ptr_sync == read_ptr_sync;
    end

    // Synchronize wfull_gray and rempty_gray
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wfull_gray_sync <= 0;
            wfull_gray_sync2 <= 0;
            wfull_gray_sync3 <= 0;
            wfull_gray_sync4 <= 0;
            wfull_gray_sync5 <= 0;
            wfull_gray_sync6 <= 0;
            wfull_gray_sync7 <= 0;
            wfull_gray_sync8 <= 0;
            wfull_gray_sync9 <= 0;
            wfull_gray_sync10 <= 0;
            wfull_gray_sync11 <= 0;
            wfull_gray_sync12 <= 0;
            wfull_gray_sync13 <= 0;
            wfull_gray_sync14 <= 0;
            wfull_gray_sync15 <= 0;
        end else begin
            wfull_gray_sync <= wfull_gray;
            wfull_gray_sync2 <= wfull_gray_sync;
            wfull_gray_sync3 <= wfull_gray_sync2;
            wfull_gray_sync4 <= wfull_gray_sync3;
            wfull_gray_sync5 <= wfull_gray_sync4;
            wfull_gray_sync6 <= wfull_gray_sync5;
            wfull_gray_sync7 <= wfull_gray_sync6;
            wfull_gray_sync8 <= wfull_gray_sync7;
            wfull_gray_sync9 <= wfull_gray_sync8;
            wfull_gray_sync10 <= wfull_gray_sync9;
            wfull_gray_sync11 <= wfull_gray_sync10;
            wfull_gray_sync12 <= wfull_gray_sync11;
            wfull_gray_sync13 <= wfull_gray_sync12;
            wfull_gray_sync14 <= wfull_gray_sync13;
            wfull_gray_sync15 <= wfull_gray_sync14;
        end
    end

    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rempty_gray_sync <= 0;
            rempty_gray_sync2 <= 0;
            rempty_gray_sync3 <= 0;
            rempty_gray_sync4 <= 0;
            rempty_gray_sync5 <= 0;
            rempty_gray_sync6 <= 0;
            rempty_gray_sync7 <= 0;
            rempty_gray_sync8 <= 0;
            rempty_gray_sync9 <= 0;
            rempty_gray_sync10 <= 0;
            rempty_gray_sync11 <= 0;
            rempty_gray_sync12 <= 0;
            rempty_gray_sync13 <= 0;
            rempty_gray_sync14 <= 0;
            rempty_gray_sync15 <= 0;
        end else begin
            rempty_gray_sync <= rempty_gray;
            rempty_gray_sync2 <= rempty_gray_sync;
            rempty_gray_sync3 <= rempty_gray_sync2;
            rempty_gray_sync4 <= rempty_gray_sync3;
            rempty_gray_sync5 <= rempty_gray_sync4;
            rempty_gray_sync6 <= rempty_gray_sync5;
            rempty_gray_sync7 <= rempty_gray_sync6;
            rempty_gray_sync8 <= rempty_gray_sync7;
            rempty_gray_sync9 <= rempty_gray_sync8;
            rempty_gray_sync10 <= rempty_gray_sync9;
            rempty_gray_sync11 <= rempty_gray_sync10;
            rempty_gray_sync12 <= rempty_gray_sync11;
            rempty_gray_sync13 <= rempty_gray_sync12;
            rempty_gray_sync14 <= rempty_gray_sync13;
            rempty_gray_sync15 <= rempty_gray_sync14;
        end
    end

    // Assign outputs
    assign wfull = wfull_gray_sync15;
    assign awfull = (write_ptr_sync + 2) == read_ptr_sync;
    assign rempty = rempty_gray_sync15;
    assign arempty = (write_ptr_sync == read_ptr_sync + 1);

    // Memory write and read
    always @(posedge wclk) begin
        if (wrst_n && winc && !wfull_gray_sync) begin
            mem[write_ptr] <= wdata;
        end
    end

    always @(posedge rclk) begin
        if (rrst_n && (!rempty_gray_sync || (FALLTHROUGH && !rempty_gray_sync))) begin
            rdata <= mem[read_ptr];
        end
    end

endmodule
