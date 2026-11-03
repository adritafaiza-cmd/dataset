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
    reg [ASIZE:0] write_ptr, read_ptr;
    reg [ASIZE:0] gray_write_ptr, gray_read_ptr;
    reg [ASIZE:0] sync_gray_read_ptr, sync_gray_write_ptr;
    reg [DSIZE-1:0] fifo_mem [0:(1<<ASIZE)-1];
    reg [ASIZE:0] gray_to_bin_sync_read_ptr, gray_to_bin_sync_write_ptr;
    reg full_flag, empty_flag;
    reg almost_full_flag, almost_empty_flag;

    // Binary to Gray conversion
    function [ASIZE:0] bin_to_gray;
        input [ASIZE:0] bin;
        bin_to_gray = bin ^ (bin >> 1);
    endfunction

    // Gray to Binary conversion
    function [ASIZE:0] gray_to_bin;
        input [ASIZE:0] gray;
        integer i;
        reg [ASIZE:0] bin;
        bin = gray;
        for (i = ASIZE-1; i >= 0; i = i - 1)
            bin[i] = bin[i+1] ^ gray[i];
        return bin;
    endfunction

    // Write domain logic
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            write_ptr <= 0;
            full_flag <= 0;
        end else begin
            if (winc && !wfull) begin
                fifo_mem[write_ptr[ASIZE-1:0]] <= wdata;
                write_ptr <= write_ptr + 1;
                full_flag <= (gray_to_bin_sync_read_ptr == {gray_write_ptr[ASIZE], ~gray_write_ptr[ASIZE-1:0]}) && (gray_to_bin_sync_read_ptr[ASIZE] != gray_write_ptr[ASIZE]);
            end
        end
    end

    // Read domain logic
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            read_ptr <= 0;
            empty_flag <= 1;
        end else begin
            if (rinc && !rempty) begin
                read_ptr <= read_ptr + 1;
                empty_flag <= (gray_to_bin_sync_write_ptr == {gray_read_ptr[ASIZE], ~gray_read_ptr[ASIZE-1:0]}) && (gray_to_bin_sync_write_ptr[ASIZE] != gray_read_ptr[ASIZE]);
            end
        end
    end

    // Write pointer logic
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n)
            gray_write_ptr <= 0;
        else
            gray_write_ptr <= bin_to_gray(write_ptr);
    end

    // Read pointer logic
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n)
            gray_read_ptr <= 0;
        else
            gray_read_ptr <= bin_to_gray(read_ptr);
    end

    // Synchronize gray_read_ptr to wclk domain
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            sync_gray_read_ptr <= 0;
        end else begin
            sync_gray_read_ptr <= gray_read_ptr;
        end
    end

    // Synchronize gray_write_ptr to rclk domain
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            sync_gray_write_ptr <= 0;
        end else begin
            sync_gray_write_ptr <= gray_write_ptr;
        end
    end

    // Convert synchronized gray pointers to binary
    always @(*) begin
        gray_to_bin_sync_read_ptr = gray_to_bin(sync_gray_read_ptr);
        gray_to_bin_sync_write_ptr = gray_to_bin(sync_gray_write_ptr);
    end

    // Determine full, empty, almost full, and almost empty flags
    assign wfull = (gray_to_bin_sync_read_ptr == {gray_write_ptr[ASIZE], ~gray_write_ptr[ASIZE-1:0]}) && (gray_to_bin_sync_read_ptr[ASIZE] != gray_write_ptr[ASIZE]);
    assign rempty = (gray_to_bin_sync_write_ptr == {gray_read_ptr[ASIZE], ~gray_read_ptr[ASIZE-1:0]}) && (gray_to_bin_sync_write_ptr[ASIZE] != gray_read_ptr[ASIZE]);
    assign awfull = (gray_to_bin_sync_read_ptr == {~gray_write_ptr[ASIZE], gray_write_ptr[ASIZE-1:0]});
    assign arempty = (gray_to_bin_sync_write_ptr == {~gray_read_ptr[ASIZE], gray_read_ptr[ASIZE-1:0]});

    // Read data output
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n)
            rdata <= 0;
        else if (rinc && !rempty)
            rdata <= fifo_mem[read_ptr[ASIZE-1:0]];
        else if (FALLTHROUGH == "TRUE" && !rempty)
            rdata <= fifo_mem[read_ptr[ASIZE-1:0]];
    end

endmodule
