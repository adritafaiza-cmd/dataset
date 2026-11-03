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

    // FIFO signals
    reg                        addr_fifo_wr_en, addr_fifo_full, addr_fifo_rd_en, addr_fifo_empty;
    reg                        data_fifo_wr_en, data_fifo_full, data_fifo_rd_en, data_fifo_empty;
    reg                        strb_fifo_wr_en, strb_fifo_full, strb_fifo_rd_en, strb_fifo_empty;
    reg                        prot_fifo_wr_en, prot_fifo_full, prot_fifo_rd_en, prot_fifo_empty;
    reg                        write_fifo_wr_en, write_fifo_full, write_fifo_rd_en, write_fifo_empty;
    reg                        ready_fifo_wr_en, ready_fifo_full, ready_fifo_rd_en, ready_fifo_empty;
    reg                        rdata_fifo_wr_en, rdata_fifo_full, rdata_fifo_rd_en, rdata_fifo_empty;
    reg                        slverr_fifo_wr_en, slverr_fifo_full, slverr_fifo_rd_en, slverr_fifo_empty;

    // Internal states
    reg                        src_setup_phase, dst_setup_phase, dst_access_phase;

    // FIFO instances
    async_fifo #(
        .DATA_WIDTH(ADDR_WIDTH),
        .LOG_DEPTH(LOG_DEPTH)
    ) fifo_addr (
        .clk_wr(src_pclk_i),
        .rst_wr(src_preset_ni),
        .din(src_paddr_i),
        .wr_en(addr_fifo_wr_en),
        .full(addr_fifo_full),
        .clk_rd(dst_pclk_i),
        .rst_rd(dst_preset_ni),
        .dout(dst_paddr_o),
        .rd_en(addr_fifo_rd_en),
        .empty(addr_fifo_empty)
    );

    async_fifo #(
        .DATA_WIDTH(DATA_WIDTH),
        .LOG_DEPTH(LOG_DEPTH)
    ) fifo_data (
        .clk_wr(src_pclk_i),
        .rst_wr(src_preset_ni),
        .din(src_pwdata_i),
        .wr_en(data_fifo_wr_en),
        .full(data_fifo_full),
        .clk_rd(dst_pclk_i),
        .rst_rd(dst_preset_ni),
        .dout(dst_pwdata_o),
        .rd_en(data_fifo_rd_en),
        .empty(data_fifo_empty)
    );

    async_fifo #(
        .DATA_WIDTH(DATA_WIDTH/8),
        .LOG_DEPTH(LOG_DEPTH)
    ) fifo_strb (
        .clk_wr(src_pclk_i),
        .rst_wr(src_preset_ni),
        .din(src_pstrb_i),
        .wr_en(strb_fifo_wr_en),
        .full(strb_fifo_full),
        .clk_rd(dst_pclk_i),
        .rst_rd(dst_preset_ni),
        .dout(dst_pstrb_o),
        .rd_en(strb_fifo_rd_en),
        .empty(strb_fifo_empty)
    );

    async_fifo #(
        .DATA_WIDTH(3),
        .LOG_DEPTH(LOG_DEPTH)
    ) fifo_prot (
        .clk_wr(src_pclk_i),
        .rst_wr(src_preset_ni),
        .din(src_pprot_i),
        .wr_en(prot_fifo_wr_en),
        .full(prot_fifo_full),
        .clk_rd(dst_pclk_i),
        .rst_rd(dst_preset_ni),
        .dout(dst_pprot_o),
        .rd_en(prot_fifo_rd_en),
        .empty(prot_fifo_empty)
    );

    async_fifo #(
        .DATA_WIDTH(1),
        .LOG_DEPTH(LOG_DEPTH)
    ) fifo_write (
        .clk_wr(src_pclk_i),
        .rst_wr(src_preset_ni),
        .din(src_pwrite_i),
        .wr_en(write_fifo_wr_en),
        .full(write_fifo_full),
        .clk_rd(dst_pclk_i),
        .rst_rd(dst_preset_ni),
        .dout(dst_pwrite_o),
        .rd_en(write_fifo_rd_en),
        .empty(write_fifo_empty)
    );

    async_fifo #(
        .DATA_WIDTH(1),
        .LOG_DEPTH(LOG_DEPTH)
    ) fifo_ready (
        .clk_wr(dst_pclk_i),
        .rst_wr(dst_preset_ni),
        .din(dst_pready_i),
        .wr_en(ready_fifo_wr_en),
        .full(ready_fifo_full),
        .clk_rd(src_pclk_i),
        .rst_rd(src_preset_ni),
        .dout(src_pready_o),
        .rd_en(ready_fifo_rd_en),
        .empty(ready_fifo_empty)
    );

    async_fifo #(
        .DATA_WIDTH(DATA_WIDTH),
        .LOG_DEPTH(LOG_DEPTH)
    ) fifo_rdata (
        .clk_wr(dst_pclk_i),
        .rst_wr(dst_preset_ni),
        .din(dst_prdata_i),
        .wr_en(rdata_fifo_wr_en),
        .full(rdata_fifo_full),
        .clk_rd(src_pclk_i),
        .rst_rd(src_preset_ni),
        .dout(src_prdata_o),
        .rd_en(rdata_fifo_rd_en),
        .empty(rdata_fifo_empty)
    );

    async_fifo #(
        .DATA_WIDTH(1),
        .LOG_DEPTH(LOG_DEPTH)
    ) fifo_slverr (
        .clk_wr(dst_pclk_i),
        .rst_wr(dst_preset_ni),
        .din(dst_pslverr_i),
        .wr_en(slverr_fifo_wr_en),
        .full(slverr_fifo_full),
        .clk_rd(src_pclk_i),
        .rst_rd(src_preset_ni),
        .dout(src_pslverr_o),
        .rd_en(slverr_fifo_rd_en),
        .empty(slverr_fifo_empty)
    );

    // Source domain logic
    always @(posedge src_pclk_i or negedge src_preset_ni) begin
        if (!src_preset_ni) begin
            src_pready_o <= 0;
            src_setup_phase <= 0;
            addr_fifo_wr_en <= 0;
            data_fifo_wr_en <= 0;
            strb_fifo_wr_en <= 0;
            prot_fifo_wr_en <= 0;
            write_fifo_wr_en <= 0;
            ready_fifo_rd_en <= 0;
        end else begin
            if (src_psel_i && src_penable_i && !src_pready_o) begin
                if (!addr_fifo_full && !data_fifo_full && !strb_fifo_full && !prot_fifo_full && !write_fifo_full) begin
                    addr_fifo_wr_en <= 1;
                    data_fifo_wr_en <= 1;
                    strb_fifo_wr_en <= 1;
                    prot_fifo_wr_en <= 1;
                    write_fifo_wr_en <= 1;
                    src_setup_phase <= 1;
                end
            end else begin
                addr_fifo_wr_en <= 0;
                data_fifo_wr_en <= 0;
                strb_fifo_wr_en <= 0;
                prot_fifo_wr_en <= 0;
                write_fifo_wr_en <= 0;
            end

            if (src_setup_phase && !addr_fifo_full && !data_fifo_full && !strb_fifo_full && !prot_fifo_full && !write_fifo_full) begin
                src_setup_phase <= 0;
            end

            if (ready_fifo_empty) begin
                ready_fifo_rd_en <= 0;
            end else begin
                ready_fifo_rd_en <= 1;
            end
        end
    end

    // Destination domain logic
    always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
        if (!dst_preset_ni) begin
            dst_psel_o <= 0;
            dst_penable_o <= 0;
            dst_setup_phase <= 0;
            dst_access_phase <= 0;
            addr_fifo_rd_en <= 0;
            data_fifo_rd_en <= 0;
            strb_fifo_rd_en <= 0;
            prot_fifo_rd_en <= 0;
            write_fifo_rd_en <= 0;
            rdata_fifo_wr_en <= 0;
            slverr_fifo_wr_en <= 0;
            ready_fifo_wr_en <= 0;
        end else begin
            if (!addr_fifo_empty && !data_fifo_empty && !strb_fifo_empty && !prot_fifo_empty && !write_fifo_empty && !dst_setup_phase && !dst_access_phase) begin
                addr_fifo_rd_en <= 1;
                data_fifo_rd_en <= 1;
                strb_fifo_rd_en <= 1;
                prot_fifo_rd_en <= 1;
                write_fifo_rd_en <= 1;
                dst_psel_o <= 1;
                dst_penable_o <= 1;
                dst_setup_phase <= 1;
            end else if (dst_setup_phase && dst_pready_i) begin
                dst_setup_phase <= 0;
                dst_access_phase <= 1;
            end else if (dst_access_phase && dst_pready_i) begin
                dst_psel_o <= 0;
                dst_penable_o <= 0;
                dst_access_phase <= 0;
                rdata_fifo_wr_en <= 1;
                slverr_fifo_wr_en <= 1;
                ready_fifo_wr_en <= 1;
            end else begin
                addr_fifo_rd_en <= 0;
                data_fifo_rd_en <= 0;
                strb_fifo_rd_en <= 0;
                prot_fifo_rd_en <= 0;
                write_fifo_rd_en <= 0;
                rdata_fifo_wr_en <= 0;
                slverr_fifo_wr_en <= 0;
                ready_fifo_wr_en <= 0;
            end
        end
    end

endmodule

module async_fifo #(
    parameter DATA_WIDTH = 32,
    parameter LOG_DEPTH = 2
)(
    input                      clk_wr,
    input                      rst_wr,
    input  [DATA_WIDTH-1:0]    din,
    input                      wr_en,
    output                     full,
    input                      clk_rd,
    input                      rst_rd,
    output [DATA_WIDTH-1:0]    dout,
    input                      rd_en,
    output                     empty
);

    localparam DEPTH = 1 << LOG_DEPTH;
    localparam ADDR_WIDTH = LOG_DEPTH;

    reg [DATA_WIDTH-1:0]       mem [0:DEPTH-1];
    reg [ADDR_WIDTH:0]         wr_ptr, rd_ptr;
    reg [ADDR_WIDTH:0]         wr_ptr_gray, rd_ptr_gray;
    reg [ADDR_WIDTH:0]         wr_ptr_gray_sync, rd_ptr_gray_sync;

    // Gray code conversion
    function [ADDR_WIDTH:0] bin_to_gray;
        input [ADDR_WIDTH:0] bin;
        bin_to_gray = (bin >> 1) ^ bin;
    endfunction

    // Write pointer logic
    always @(posedge clk_wr or negedge rst_wr) begin
        if (!rst_wr) begin
            wr_ptr <= 0;
            wr_ptr_gray <= 0;
        end else if (wr_en && !full) begin
            mem[wr_ptr[ADDR_WIDTH-1:0]] <= din;
            wr_ptr <= wr_ptr + 1;
            wr_ptr_gray <= bin_to_gray(wr_ptr + 1);
        end
    end

    // Read pointer logic
    always @(posedge clk_rd or negedge rst_rd) begin
        if (!rst_rd) begin
            rd_ptr <= 0;
            rd_ptr_gray <= 0;
        end else if (rd_en && !empty) begin
            rd_ptr <= rd_ptr + 1;
            rd_ptr_gray <= bin_to_gray(rd_ptr + 1);
        end
    end

    // Gray code synchronization
    always @(posedge clk_wr or negedge rst_wr) begin
        if (!rst_wr) begin
            rd_ptr_gray_sync <= 0;
        end else begin
            rd_ptr_gray_sync <= rd_ptr_gray;
        end
    end

    always @(posedge clk_rd or negedge rst_rd) begin
        if (!rst_rd) begin
            wr_ptr_gray_sync <= 0;
        end else begin
            wr_ptr_gray_sync <= wr_ptr_gray;
        end
    end

    // Full and empty flags
    assign full = (wr_ptr_gray[ADDR_WIDTH] != wr_ptr_gray_sync[ADDR_WIDTH]) && (wr_ptr_gray[ADDR_WIDTH-1:0] == rd_ptr_gray_sync[ADDR_WIDTH-1:0]);
    assign empty = (wr_ptr_gray_sync[ADDR_WIDTH] == rd_ptr_gray[ADDR_WIDTH]) && (wr_ptr_gray_sync[ADDR_WIDTH-1:0] == rd_ptr_gray[ADDR_WIDTH-1:0]);

    // Data output
    always @(posedge clk_rd or negedge rst_rd) begin
        if (!rst_rd) begin
            dout <= 0;
        end else if (rd_en && !empty) begin
            dout <= mem[rd_ptr[ADDR_WIDTH-1:0]];
        end
    end

endmodule
