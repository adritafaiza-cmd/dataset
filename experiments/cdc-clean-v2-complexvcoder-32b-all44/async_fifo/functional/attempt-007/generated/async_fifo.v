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
    reg [ASIZE:0] write_ptr_gray, read_ptr_gray;
    reg [ASIZE:0] write_ptr_bin, read_ptr_bin;
    reg [ASIZE:0] gray_next_w, gray_next_r;
    reg [ASIZE:0] write_ptr_gray_next, read_ptr_gray_next;
    reg [ASIZE:0] write_ptr_bin_next, read_ptr_bin_next;
    reg           wfull_int, rempty_int;
    reg [ASIZE:0] gray_sync_rclk, gray_sync_wclk;
    reg [DSIZE-1:0] mem [0:(1<<ASIZE)-1];

    // Write domain logic
    gray_counter gray_counter_w (
        .clk(wclk),
        .rst_n(wrst_n),
        .inc(winc),
        .gray_code(write_ptr_gray),
        .next_gray_code(gray_next_w)
    );

    // Read domain logic
    gray_counter gray_counter_r (
        .clk(rclk),
        .rst_n(rrst_n),
        .inc(rinc),
        .gray_code(read_ptr_gray),
        .next_gray_code(gray_next_r)
    );

    // Write domain pointer updates
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            write_ptr_gray <= 0;
        end else if (winc && !wfull_int) begin
            write_ptr_gray <= gray_next_w;
        end
    end

    // Read domain pointer updates
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            read_ptr_gray <= 0;
        end else if (rinc && !rempty_int) begin
            read_ptr_gray <= gray_next_r;
        end
    end

    // Gray to binary conversion
    always @(*) begin
        write_ptr_bin = write_ptr_gray ^ (write_ptr_gray >> 1);
        read_ptr_bin = read_ptr_gray ^ (read_ptr_gray >> 1);
        write_ptr_bin_next = write_ptr_gray_next ^ (write_ptr_gray_next >> 1);
        read_ptr_bin_next = read_ptr_gray_next ^ (read_ptr_gray_next >> 1);
    end

    // Next gray code calculation
    always @(*) begin
        write_ptr_gray_next = (write_ptr_gray + 1) ^ write_ptr_gray;
        read_ptr_gray_next = (read_ptr_gray + 1) ^ read_ptr_gray;
    end

    // Synchronization of gray codes between domains
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            gray_sync_wclk <= 0;
        end else begin
            gray_sync_wclk <= write_ptr_gray;
        end
    end

    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            gray_sync_rclk <= 0;
        end else begin
            gray_sync_rclk <= read_ptr_gray;
        end
    end

    // Full and empty flags
    always @(*) begin
        wfull_int = (write_ptr_bin_next == (read_ptr_bin + 1));
        rempty_int = (write_ptr_bin == read_ptr_bin);
        awfull = (write_ptr_bin_next == (read_ptr_bin + 2));
        arempty = (write_ptr_bin == (read_ptr_bin + 1));
    end

    // FIFO memory write
    always @(posedge wclk) begin
        if (winc && !wfull_int) begin
            mem[write_ptr_bin] <= wdata;
        end
    end

    // FIFO memory read
    always @(posedge rclk) begin
        if (rinc && !rempty_int) begin
            rdata <= mem[read_ptr_bin];
        end else if (FALLTHROUGH && !rempty_int) begin
            rdata <= mem[read_ptr_bin];
        end
    end

    // Output assignments
    assign wfull = wfull_int;
    assign rempty = rempty_int;

endmodule

module gray_counter (
        input  wire             clk,
        input  wire             rst_n,
        input  wire             inc,
        input  wire [ASIZE:0]   gray_code,
        output wire [ASIZE:0]   next_gray_code
    );

    // Internal signals
    reg [ASIZE:0] bin_code, bin_code_next, bin_code_reg;

    // Gray to binary conversion
    always @(*) begin
        bin_code = gray_code ^ (gray_code >> 1);
    end

    // Binary code next value
    always @(*) begin
        if (inc) begin
            bin_code_next = bin_code + 1;
        end else begin
            bin_code_next = bin_code;
        end
    end

    // Register binary code on clock edge
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bin_code_reg <= 0;
        end else begin
            bin_code_reg <= bin_code_next;
        end
    end

    // Binary to gray conversion
    always @(*) begin
        next_gray_code = bin_code_reg ^ (bin_code_reg >> 1);
    end

endmodule
