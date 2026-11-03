module apb_cdc #(
    parameter ADDR_WIDTH = 8,
    parameter DATA_WIDTH = 32,
    parameter LOG_DEPTH = 1
)(
    input                      src_pclk_i,
    input                      src_preset_ni,
    input                      src_psel_i,
    input                      src_penable_i,
    input                      src_pwrite_i,
    input  [ADDR_WIDTH-1:0]    src_paddr_i,
    input  [DATA_WIDTH-1:0]    src_pwdata_i,
    input  [DATA_WIDTH/8-1:0]  src_pstrb_i,
    input  [2:0]               src_pprot_i,
    output                     src_pready_o,
    output [DATA_WIDTH-1:0]    src_prdata_o,
    output                     src_pslverr_o,
    input                      dst_pclk_i,
    input                      dst_preset_ni,
    output                     dst_psel_o,
    output                     dst_penable_o,
    output                     dst_pwrite_o,
    output [ADDR_WIDTH-1:0]    dst_paddr_o,
    output [DATA_WIDTH-1:0]    dst_pwdata_o,
    output [DATA_WIDTH/8-1:0]  dst_pstrb_o,
    output [2:0]               dst_pprot_o,
    input                      dst_pready_i,
    input  [DATA_WIDTH-1:0]    dst_prdata_i,
    input                      dst_pslverr_i
);

    // Internal signals
    reg                        req_fifo_push;
    reg                        req_fifo_pop;
    wire                       req_fifo_full;
    wire                       req_fifo_empty;
    wire [ADDR_WIDTH+DATA_WIDTH+DATA_WIDTH/8+4-1:0] req_fifo_data;

    reg                        resp_fifo_push;
    reg                        resp_fifo_pop;
    wire                       resp_fifo_full;
    wire                       resp_fifo_empty;
    wire [DATA_WIDTH+1-1:0]    resp_fifo_data;

    reg                        req_valid;
    reg                        req_ready;
    reg                        resp_valid;
    reg                        resp_ready;

    // FIFO instantiation
    fifo_sync #(
        .DATA_WIDTH(ADDR_WIDTH+DATA_WIDTH+DATA_WIDTH/8+4)
    ) req_fifo_inst (
        .clk_i(src_pclk_i),
        .rst_ni(src_preset_ni),
        .push(req_fifo_push),
        .pop(req_fifo_pop),
        .din({src_psel_i, src_penable_i, src_pwrite_i, src_paddr_i, src_pwdata_i, src_pstrb_i, src_pprot_i}),
        .full(req_fifo_full),
        .empty(req_fifo_empty),
        .dout(req_fifo_data)
    );

    fifo_sync #(
        .DATA_WIDTH(DATA_WIDTH+1)
    ) resp_fifo_inst (
        .clk_i(src_pclk_i),
        .rst_ni(src_preset_ni),
        .push(resp_fifo_push),
        .pop(resp_fifo_pop),
        .din({dst_prdata_i, dst_pslverr_i}),
        .full(resp_fifo_full),
        .empty(resp_fifo_empty),
        .dout(resp_fifo_data)
    );

    // Request side logic
    always @(posedge src_pclk_i or negedge src_preset_ni) begin
        if (!src_preset_ni) begin
            req_valid <= 0;
            req_ready <= 0;
            src_pready_o <= 0;
        end else begin
            req_ready <= !req_fifo_full;
            src_pready_o <= 0;

            if (src_psel_i && src_penable_i && req_ready) begin
                req_valid <= 1;
                req_fifo_push <= 1;
            end else begin
                req_fifo_push <= 0;
            end

            if (req_fifo_empty) begin
                req_valid <= 0;
            end

            if (req_valid && req_fifo_empty) begin
                src_pready_o <= 1;
                req_valid <= 0;
            end
        end
    end

    // Response side logic
    always @(posedge src_pclk_i or negedge src_preset_ni) begin
        if (!src_preset_ni) begin
            resp_ready <= 0;
            src_prdata_o <= 0;
            src_pslverr_o <= 0;
        end else begin
            resp_ready <= !resp_fifo_full;
            resp_fifo_pop <= 0;

            if (resp_fifo_empty) begin
                src_prdata_o <= 0;
                src_pslverr_o <= 0;
            end else begin
                src_prdata_o <= resp_fifo_data[DATA_WIDTH-1:0];
                src_pslverr_o <= resp_fifo_data[DATA_WIDTH];
                resp_fifo_pop <= 1;
            end
        end
    end

    // Destination side logic
    always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
        if (!dst_preset_ni) begin
            dst_psel_o <= 0;
            dst_penable_o <= 0;
            dst_pwrite_o <= 0;
            dst_paddr_o <= 0;
            dst_pwdata_o <= 0;
            dst_pstrb_o <= 0;
            dst_pprot_o <= 0;
        end else begin
            if (!req_fifo_empty) begin
                dst_psel_o <= req_fifo_data[0];
                dst_penable_o <= req_fifo_data[1];
                dst_pwrite_o <= req_fifo_data[2];
                dst_paddr_o <= req_fifo_data[3+ADDR_WIDTH-1:3];
                dst_pwdata_o <= req_fifo_data[3+ADDR_WIDTH+DATA_WIDTH-1:3+ADDR_WIDTH];
                dst_pstrb_o <= req_fifo_data[3+ADDR_WIDTH+DATA_WIDTH+DATA_WIDTH/8-1:3+ADDR_WIDTH+DATA_WIDTH];
                dst_pprot_o <= req_fifo_data[3+ADDR_WIDTH+DATA_WIDTH+DATA_WIDTH/8+3-1:3+ADDR_WIDTH+DATA_WIDTH+DATA_WIDTH/8];
            end else begin
                dst_psel_o <= 0;
                dst_penable_o <= 0;
                dst_pwrite_o <= 0;
                dst_paddr_o <= 0;
                dst_pwdata_o <= 0;
                dst_pstrb_o <= 0;
                dst_pprot_o <= 0;
            end

            if (dst_penable_o && dst_pready_i) begin
                req_fifo_pop <= 1;
            end else begin
                req_fifo_pop <= 0;
            end
        end
    end

    // FIFO Sync module
    module fifo_sync #(
        parameter DATA_WIDTH = 8
    ) (
        input                      clk_i,
        input                      rst_ni,
        input                      push,
        input                      pop,
        input  [DATA_WIDTH-1:0]    din,
        output                     full,
        output                     empty,
        output [DATA_WIDTH-1:0]    dout
    );

        localparam DEPTH = 2 ** LOG_DEPTH;
        reg [DATA_WIDTH-1:0]       mem [0:DEPTH-1];
        reg [$clog2(DEPTH):0]      wr_ptr;
        reg [$clog2(DEPTH):0]      rd_ptr;
        reg [$clog2(DEPTH):0]      rd_ptr_gray;
        reg [$clog2(DEPTH):0]      wr_ptr_gray;

        wire [$clog2(DEPTH):0]     rd_ptr_bin;
        wire [$clog2(DEPTH):0]     wr_ptr_bin;

        // Binary to Gray conversion
        function [$clog2(DEPTH):0] bin2gray;
            input [$clog2(DEPTH):0] bin;
            bin2gray = bin ^ (bin >> 1);
        endfunction

        // Gray to Binary conversion
        function [$clog2(DEPTH):0] gray2bin;
            input [$clog2(DEPTH):0] gray;
            integer i;
            gray2bin = gray;
            for (i = $clog2(DEPTH)-1; i >= 0; i = i - 1) begin
                gray2bin[i] = gray2bin[i] ^ gray2bin[i+1];
            end
        endfunction

        always @(posedge clk_i or negedge rst_ni) begin
            if (!rst_ni) begin
                wr_ptr <= 0;
                rd_ptr_gray <= 0;
            end else begin
                if (push && !full) begin
                    mem[wr_ptr[$clog2(DEPTH)-1:0]] <= din;
                    wr_ptr <= wr_ptr + 1;
                end
            end
        end

        always @(posedge clk_i or negedge rst_ni) begin
            if (!rst_ni) begin
                rd_ptr <= 0;
            end else begin
                if (pop && !empty) begin
                    rd_ptr <= rd_ptr + 1;
                end
            end
        end

        always @(posedge clk_i) begin
            rd_ptr_gray <= bin2gray(rd_ptr);
            wr_ptr_gray <= bin2gray(wr_ptr);
        end

        assign rd_ptr_bin = gray2bin(rd_ptr_gray);
        assign wr_ptr_bin = gray2bin(wr_ptr_gray);

        assign empty = (wr_ptr_gray == rd_ptr_gray);
        assign full = (wr_ptr_gray[$clog2(DEPTH)-1:0] == rd_ptr_gray[$clog2(DEPTH)-1:0]) && (wr_ptr_gray[$clog2(DEPTH)] != rd_ptr_gray[$clog2(DEPTH)]);

        assign dout = mem[rd_ptr_bin[$clog2(DEPTH)-1:0]];
    endmodule

endmodule
