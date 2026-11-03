module apbxclk #(
        parameter C_APB_ADDR_WIDTH = 12,
        parameter C_APB_DATA_WIDTH = 32,
        parameter [0:0] OPT_REGISTERED = 1'b0,
        localparam AW = C_APB_ADDR_WIDTH,
        localparam DW = C_APB_DATA_WIDTH
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

    // CDC registers
    cdc_register #(.WIDTH(AW)) cdc_paddr (
        .src_clk(S_APB_PCLK), .src_rst_n(S_PRESETn),
        .dst_clk(M_APB_PCLK), .dst_rst_n(M_PRESETn),
        .din(S_APB_PADDR), .dout(d_paddr)
    );

    cdc_register #(.WIDTH(1)) cdc_pwrite (
        .src_clk(S_APB_PCLK), .src_rst_n(S_PRESETn),
        .dst_clk(M_APB_PCLK), .dst_rst_n(M_PRESETn),
        .din(S_APB_PWRITE), .dout(d_pwrite)
    );

    cdc_register #(.WIDTH(DW)) cdc_pwdata (
        .src_clk(S_APB_PCLK), .src_rst_n(S_PRESETn),
        .dst_clk(M_APB_PCLK), .dst_rst_n(M_PRESETn),
        .din(S_APB_PWDATA), .dout(d_pwdata)
    );

    cdc_register #(.WIDTH(DW/8)) cdc_pwstrb (
        .src_clk(S_APB_PCLK), .src_rst_n(S_PRESETn),
        .dst_clk(M_APB_PCLK), .dst_rst_n(M_PRESETn),
        .din(S_APB_PWSTRB), .dout(d_pwstrb)
    );

    cdc_register #(.WIDTH(3)) cdc_pprot (
        .src_clk(S_APB_PCLK), .src_rst_n(S_PRESETn),
        .dst_clk(M_APB_PCLK), .dst_rst_n(M_PRESETn),
        .din(S_APB_PPROT), .dout(d_pprot)
    );

    cdc_register #(.WIDTH(1)) cdc_pready (
        .src_clk(M_APB_PCLK), .src_rst_n(M_PRESETn),
        .dst_clk(S_APB_PCLK), .dst_rst_n(S_PRESETn),
        .din(M_APB_PREADY), .dout(d_pready)
    );

    cdc_register #(.WIDTH(DW)) cdc_prdata (
        .src_clk(M_APB_PCLK), .src_rst_n(M_PRESETn),
        .dst_clk(S_APB_PCLK), .dst_rst_n(S_PRESETn),
        .din(M_APB_PRDATA), .dout(d_prdata)
    );

    cdc_register #(.WIDTH(1)) cdc_pslverr (
        .src_clk(M_APB_PCLK), .src_rst_n(M_PRESETn),
        .dst_clk(S_APB_PCLK), .dst_rst_n(S_PRESETn),
        .din(M_APB_PSLVERR), .dout(d_pslverr)
    );

    // Internal signals
    reg [AW-1:0] d_paddr;
    reg d_pwrite;
    reg [DW-1:0] d_pwdata;
    reg [DW/8-1:0] d_pwstrb;
    reg [2:0] d_pprot;
    reg d_pready;
    reg [DW-1:0] d_prdata;
    reg d_pslverr;
    reg s_apb_start;
    reg m_apb_start;
    reg m_apb_done;
    reg s_apb_ready;

    // Source APB interface logic
    always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
        if (!S_PRESETn) begin
            S_APB_PREADY <= 1'b0;
            s_apb_start <= 1'b0;
            s_apb_ready <= 1'b0;
        end else begin
            if (S_APB_PSEL && S_APB_PENABLE && !s_apb_start) begin
                s_apb_start <= 1'b1;
            end
            if (d_pready) begin
                S_APB_PREADY <= 1'b1;
                s_apb_ready <= 1'b1;
            end else if (S_APB_PREADY) begin
                S_APB_PREADY <= 1'b0;
                s_apb_start <= 1'b0;
                s_apb_ready <= 1'b0;
            end
        end
    end

    // Destination APB interface logic
    always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
        if (!M_PRESETn) begin
            M_PRESETn <= 1'b0;
            M_APB_PSEL <= 1'b0;
            M_APB_PENABLE <= 1'b0;
            m_apb_start <= 1'b0;
            m_apb_done <= 1'b0;
        end else begin
            M_PRESETn <= 1'b1;
            if (s_apb_start && !m_apb_start) begin
                M_APB_PSEL <= 1'b1;
                m_apb_start <= 1'b1;
            end
            if (M_APB_PENABLE && M_APB_PREADY) begin
                M_APB_PENABLE <= 1'b0;
                M_APB_PSEL <= 1'b0;
                m_apb_done <= 1'b1;
            end else if (m_apb_done) begin
                m_apb_start <= 1'b0;
                m_apb_done <= 1'b0;
            end else if (!M_APB_PENABLE && m_apb_start) begin
                M_APB_PENABLE <= 1'b1;
            end
        end
    end

    // Assign outputs
    assign S_APB_PRDATA = d_prdata;
    assign S_APB_PSLVERR = d_pslverr;
    assign M_APB_PADDR = d_paddr;
    assign M_APB_PWRITE = d_pwrite;
    assign M_APB_PWDATA = d_pwdata;
    assign M_APB_PWSTRB = d_pwstrb;
    assign M_APB_PPROT = d_pprot;

endmodule

module cdc_register #(
        parameter WIDTH = 1
    ) (
        input wire src_clk, src_rst_n,
        input wire dst_clk, dst_rst_n,
        input wire [WIDTH-1:0] din,
        output reg [WIDTH-1:0] dout
    );

    reg [WIDTH-1:0] reg1, reg2;

    always @(posedge src_clk or negedge src_rst_n) begin
        if (!src_rst_n)
            reg1 <= {WIDTH{1'b0}};
        else
            reg1 <= din;
    end

    always @(posedge dst_clk or negedge dst_rst_n) begin
        if (!dst_rst_n)
            reg2 <= {WIDTH{1'b0}};
        else
            reg2 <= reg1;
    end

    assign dout = reg2;

endmodule
