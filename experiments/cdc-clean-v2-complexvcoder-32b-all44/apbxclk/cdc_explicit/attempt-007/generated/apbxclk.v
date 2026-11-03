module apbxclk #(
    parameter C_APB_ADDR_WIDTH = 12,
    parameter C_APB_DATA_WIDTH = 32,
    parameter [0:0] OPT_REGISTERED = 1'b0,
    localparam AW = C_APB_ADDR_WIDTH,
    localparam DW = C_APB_DATA_WIDTH,
    localparam DATA_WIDTH = DW*2 + AW + 4
) (
    input wire S_APB_PCLK, S_PRESETn,
    input wire S_APB_PSEL,
    input wire S_APB_PENABLE,
    output reg S_APB_PREADY,
    input wire [AW-1:0] S_APB_PADDR,
    input wire S_APB_PWRITE,
    input wire [DW-1:0] S_APB_PWDATA,
    input wire [DW/8-1:0] S_APB_PWSTRB,
    input wire [2:0] S_APB_PPROT,
    output wire [DW-1:0] S_APB_PRDATA,
    output wire S_APB_PSLVERR,
    input wire M_APB_PCLK,
    output reg M_PRESETn,
    output reg M_APB_PSEL,
    output reg M_APB_PENABLE,
    input wire M_APB_PREADY,
    output wire [AW-1:0] M_APB_PADDR,
    output wire M_APB_PWRITE,
    output wire [DW-1:0] M_APB_PWDATA,
    output wire [DW/8-1:0] M_APB_PWSTRB,
    output wire [2:0] M_APB_PPROT,
    input wire [DW-1:0] M_APB_PRDATA,
    input wire M_APB_PSLVERR
);

    // Internal signals
    reg [DATA_WIDTH-1:0] apb_din_wire;
    reg apb_wr_en_wire;
    reg apb_rd_en_wire;
    wire [DATA_WIDTH-1:0] apb_dout_wire;
    reg apb_full;
    reg apb_empty;
    reg s_sync_reset;
    reg m_sync_reset;
    reg s_apb_pready_reg;
    reg m_apb_psel_reg;
    reg m_apb_penable_reg;
    reg [DW-1:0] s_apb_prdata_reg;
    reg s_apb_pslverr_reg;

    // Instantiate asynchronous reset synchronizers
    async_reset_sync s_async_reset_sync (
        .async_reset_in(S_PRESETn),
        .sync_reset_out(s_sync_reset),
        .clk(S_APB_PCLK)
    );

    async_reset_sync m_async_reset_sync (
        .async_reset_in(S_PRESETn),
        .sync_reset_out(m_sync_reset),
        .clk(M_APB_PCLK)
    );

    // Instantiate cross-domain FIFO
    cdc_fifo #(.DATA_WIDTH(DATA_WIDTH)) cdc_fifo_inst (
        .wr_clk(S_APB_PCLK),
        .wr_reset(s_sync_reset),
        .din(apb_din_wire),
        .wr_en(apb_wr_en_wire),
        .full(apb_full),
        .rd_clk(M_APB_PCLK),
        .rd_reset(m_sync_reset),
        .dout(apb_dout_wire),
        .rd_en(apb_rd_en_wire),
        .empty(apb_empty)
    );

    // Pack APB signals into a single bus for FIFO
    always @(*) begin
        apb_din_wire = {S_APB_PWDATA, S_APB_PADDR, S_APB_PWRITE, S_APB_PWSTRB, S_APB_PPROT};
    end

    // Write enable for FIFO
    always @(posedge S_APB_PCLK or posedge s_sync_reset) begin
        if (s_sync_reset) begin
            apb_wr_en_wire <= 1'b0;
        end else if (S_APB_PSEL && S_APB_PENABLE && !apb_full) begin
            apb_wr_en_wire <= 1'b1;
        end else begin
            apb_wr_en_wire <= 1'b0;
        end
    end

    // Read enable for FIFO
    always @(posedge M_APB_PCLK or posedge m_sync_reset) begin
        if (m_sync_reset) begin
            apb_rd_en_wire <= 1'b0;
        end else if (!apb_empty && !M_APB_PENABLE) begin
            apb_rd_en_wire <= 1'b1;
        end else begin
            apb_rd_en_wire <= 1'b0;
        end
    end

    // Unpack APB signals from FIFO
    reg [DW-1:0] m_apb_pwdata_reg;
    reg [AW-1:0] m_apb_paddr_reg;
    reg m_apb_pwrite_reg;
    reg [DW/8-1:0] m_apb_pwstrb_reg;
    reg [2:0] m_apb_pprot_reg;

    always @(posedge M_APB_PCLK or posedge m_sync_reset) begin
        if (m_sync_reset) begin
            m_apb_pwdata_reg <= 0;
            m_apb_paddr_reg <= 0;
            m_apb_pwrite_reg <= 0;
            m_apb_pwstrb_reg <= 0;
            m_apb_pprot_reg <= 0;
        end else if (apb_rd_en_wire) begin
            m_apb_pwdata_reg <= apb_dout_wire[DW*2-1:DW];
            m_apb_paddr_reg <= apb_dout_wire[DW*2+AW-1:DW*2];
            m_apb_pwrite_reg <= apb_dout_wire[DW*2+AW];
            m_apb_pwstrb_reg <= apb_dout_wire[DW*2+AW+DW/8-1:DW*2+AW+1];
            m_apb_pprot_reg <= apb_dout_wire[DW*2+AW+DW/8+2:DW*2+AW+DW/8+1];
        end
    end

    // Drive M_APB interface
    always @(posedge M_APB_PCLK or posedge m_sync_reset) begin
        if (m_sync_reset) begin
            M_PRESETn <= 1'b0;
            M_APB_PSEL <= 1'b0;
            M_APB_PENABLE <= 1'b0;
            M_APB_PADDR <= 0;
            M_APB_PWRITE <= 0;
            M_APB_PWDATA <= 0;
            M_APB_PWSTRB <= 0;
            M_APB_PPROT <= 0;
        end else begin
            M_PRESETn <= S_PRESETn;
            M_APB_PSEL <= m_apb_psel_reg;
            M_APB_PENABLE <= m_apb_penable_reg;
            M_APB_PADDR <= m_apb_paddr_reg;
            M_APB_PWRITE <= m_apb_pwrite_reg;
            M_APB_PWDATA <= m_apb_pwdata_reg;
            M_APB_PWSTRB <= m_apb_pwstrb_reg;
            M_APB_PPROT <= m_apb_pprot_reg;
        end
    end

    // Control logic for M_APB interface
    always @(posedge M_APB_PCLK or posedge m_sync_reset) begin
        if (m_sync_reset) begin
            m_apb_psel_reg <= 1'b0;
            m_apb_penable_reg <= 1'b0;
        end else if (!apb_empty && !M_APB_PENABLE) begin
            m_apb_psel_reg <= 1'b1;
            m_apb_penable_reg <= 1'b1;
        end else if (M_APB_PREADY) begin
            m_apb_psel_reg <= 1'b0;
            m_apb_penable_reg <= 1'b0;
        end
    end

    // Control logic for S_APB interface
    always @(posedge S_APB_PCLK or posedge s_sync_reset) begin
        if (s_sync_reset) begin
            S_APB_PREADY <= 1'b0;
            s_apb_prdata_reg <= 0;
            s_apb_pslverr_reg <= 0;
        end else if (M_APB_PREADY) begin
            S_APB_PREADY <= 1'b1;
            s_apb_prdata_reg <= M_APB_PRDATA;
            s_apb_pslverr_reg <= M_APB_PSLVERR;
        end else if (S_APB_PREADY) begin
            S_APB_PREADY <= 1'b0;
        end
    end

    // Register crossing if OPT_REGISTERED is set
    generate
        if (OPT_REGISTERED == 1'b1) begin : registered_case
            reg [DW-1:0] s_apb_prdata_reg1;
            reg s_apb_pslverr_reg1;

            always @(posedge S_APB_PCLK or posedge s_sync_reset) begin
                if (s_sync_reset) begin
                    s_apb_prdata_reg1 <= 0;
                    s_apb_pslverr_reg1 <= 0;
                end else begin
                    s_apb_prdata_reg1 <= s_apb_prdata_reg;
                    s_apb_pslverr_reg1 <= s_apb_pslverr_reg;
                end
            end

            assign S_APB_PRDATA = s_apb_prdata_reg1;
            assign S_APB_PSLVERR = s_apb_pslverr_reg1;
        end else begin : non_registered_case
            assign S_APB_PRDATA = s_apb_prdata_reg;
            assign S_APB_PSLVERR = s_apb_pslverr_reg;
        end
    endgenerate

endmodule

module async_reset_sync (
    input wire async_reset_in,
    output reg sync_reset_out,
    input wire clk
);

    reg rst_sync1, rst_sync2;

    always @(posedge clk or negedge async_reset_in) begin
        if (!async_reset_in) begin
            rst_sync1 <= 1'b1;
            rst_sync2 <= 1'b1;
        end else begin
            rst_sync1 <= 1'b0;
            rst_sync2 <= rst_sync1;
        end
    end

    assign sync_reset_out = rst_sync2;

endmodule

module cdc_fifo #(
    parameter DATA_WIDTH = 32
) (
    input wire wr_clk,
    input wire wr_reset,
    input wire [DATA_WIDTH-1:0] din,
    input wire wr_en,
    output reg full,
    input wire rd_clk,
    input wire rd_reset,
    output reg [DATA_WIDTH-1:0] dout,
    input wire rd_en,
    output reg empty
);

    reg [DATA_WIDTH-1:0] fifo_mem [7:0];
    reg [2:0] wr_ptr, rd_ptr;
    reg [2:0] wr_ptr_gray, rd_ptr_gray;
    reg [2:0] wr_ptr_gray_sync, rd_ptr_gray_sync;

    // Gray code conversion
    function [2:0] gray_encode;
        input [2:0] binary;
        gray_encode = binary ^ (binary >> 1);
    endfunction

    // Write pointer logic
    always @(posedge wr_clk or posedge wr_reset) begin
        if (wr_reset) begin
            wr_ptr <= 3'b000;
            wr_ptr_gray <= 3'b000;
        end else if (wr_en && !full) begin
            fifo_mem[wr_ptr] <= din;
            wr_ptr <= wr_ptr + 1;
            wr_ptr_gray <= gray_encode(wr_ptr + 1);
        end
    end

    // Read pointer logic
    always @(posedge rd_clk or posedge rd_reset) begin
        if (rd_reset) begin
            rd_ptr <= 3'b000;
            rd_ptr_gray <= 3'b000;
        end else if (rd_en && !empty) begin
            rd_ptr <= rd_ptr + 1;
            rd_ptr_gray <= gray_encode(rd_ptr + 1);
        end
    end

    // Gray code synchronization
    always @(posedge wr_clk or posedge wr_reset) begin
        if (wr_reset) begin
            wr_ptr_gray_sync <= 3'b000;
        end else begin
            wr_ptr_gray_sync <= rd_ptr_gray;
        end
    end

    always @(posedge rd_clk or posedge rd_reset) begin
        if (rd_reset) begin
            rd_ptr_gray_sync <= 3'b000;
        end else begin
            rd_ptr_gray_sync <= wr_ptr_gray;
        end
    end

    // Full and empty flags
    always @(*) begin
        full = (wr_ptr_gray_sync == gray_encode(wr_ptr + 1));
        empty = (wr_ptr_gray_sync == rd_ptr_gray);
    end

    // Output data
    always @(posedge rd_clk or posedge rd_reset) begin
        if (rd_reset) begin
            dout <= 0;
        end else if (rd_en && !empty) begin
            dout <= fifo_mem[rd_ptr];
        end
    end

endmodule
