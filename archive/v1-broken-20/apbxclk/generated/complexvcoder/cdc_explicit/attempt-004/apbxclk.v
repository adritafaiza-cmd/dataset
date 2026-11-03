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

    reg clk_s_apb;
    reg reset_s_apb;
    reg s_apb_psel;
    reg s_apb_penable;
    reg [AW-1:0] s_apb_paddr;
    reg s_apb_pwrite;
    reg [DW-1:0] s_apb_pwdata;
    reg [DW/8-1:0] s_apb_pwstrb;
    reg [2:0] s_apb_pprot;
    wire s_apb_pready;
    wire [DW-1:0] s_apb_prdata;
    wire s_apb_pslverr;

    reg clk_m_apb;
    reg reset_m_apb;
    reg m_apb_psel;
    reg m_apb_penable;
    reg [AW-1:0] m_apb_paddr;
    reg m_apb_pwrite;
    reg [DW-1:0] m_apb_pwdata;
    reg [DW/8-1:0] m_apb_pwstrb;
    reg [2:0] m_apb_pprot;
    wire m_apb_pready;
    wire [DW-1:0] m_apb_prdata;
    wire m_apb_pslverr;

    synchronizer #(.WIDTH(1)) synchronizer_s_apb (
        .clk(S_APB_PCLK),
        .reset(S_PRESETn),
        .in(clk_s_apb)
    );

    synchronizer #(.WIDTH(1)) synchronizer_s_presetn (
        .clk(S_APB_PCLK),
        .reset(S_PRESETn),
        .in(reset_s_apb)
    );

    synchronizer #(.WIDTH(1)) synchronizer_s_psel (
        .clk(S_APB_PCLK),
        .reset(S_PRESETn),
        .in(s_apb_psel)
    );

    synchronizer #(.WIDTH(1)) synchronizer_s_penable (
        .clk(S_APB_PCLK),
        .reset(S_PRESETn),
        .in(s_apb_penable)
    );

    synchronizer #(.WIDTH(AW)) synchronizer_s_paddr (
        .clk(S_APB_PCLK),
        .reset(S_PRESETn),
        .in(s_apb_paddr)
    );

    synchronizer #(.WIDTH(1)) synchronizer_s_pwrite (
        .clk(S_APB_PCLK),
        .reset(S_PRESETn),
        .in(s_apb_pwrite)
    );

    synchronizer #(.WIDTH(DW)) synchronizer_s_pwdata (
        .clk(S_APB_PCLK),
        .reset(S_PRESETn),
        .in(s_apb_pwdata)
    );

    synchronizer #(.WIDTH(DW/8)) synchronizer_s_pwstrb (
        .clk(S_APB_PCLK),
        .reset(S_PRESETn),
        .in(s_apb_pwstrb)
    );

    synchronizer #(.WIDTH(3)) synchronizer_s_pprot (
        .clk(S_APB_PCLK),
        .reset(S_PRESETn),
        .in(s_apb_pprot)
    );

    synchronizer #(.WIDTH(1)) synchronizer_s_pready (
        .clk(S_APB_PCLK),
        .reset(S_PRESETn),
        .in(s_apb_pready)
    );

    synchronizer #(.WIDTH(DW)) synchronizer_s_prdata (
        .clk(S_APB_PCLK),
        .reset(S_PRESETn),
        .in(s_apb_prdata)
    );

    synchronizer #(.WIDTH(1)) synchronizer_s_pslverr (
        .clk(S_APB_PCLK),
        .reset(S_PRESETn),
        .in(s_apb_pslverr)
    );

    synchronizer #(.WIDTH(1)) synchronizer_m_apb (
        .clk(M_APB_PCLK),
        .reset(M_PRESETn),
        .in(clk_m_apb)
    );

    synchronizer #(.WIDTH(1)) synchronizer_m_presetn (
        .clk(M_APB_PCLK),
        .reset(M_PRESETn),
        .in(reset_m_apb)
    );

    synchronizer #(.WIDTH(1)) synchronizer_m_psel (
        .clk(M_APB_PCLK),
        .reset(M_PRESETn),
        .in(m_apb_psel)
    );

    synchronizer #(.WIDTH(1)) synchronizer_m_penable (
        .clk(M_APB_PCLK),
        .reset(M_PRESETn),
        .in(m_apb_penable)
    );

    synchronizer #(.WIDTH(AW)) synchronizer_m_paddr (
        .clk(M_APB_PCLK),
        .reset(M_PRESETn),
        .in(m_apb_paddr)
    );

    synchronizer #(.WIDTH(1)) synchronizer_m_pwrite (
        .clk(M_APB_PCLK),
        .reset(M_PRESETn),
        .in(m_apb_pwrite)
    );

    synchronizer #(.WIDTH(DW)) synchronizer_m_pwdata (
        .clk(M_APB_PCLK),
        .reset(M_PRESETn),
        .in(m_apb_pwdata)
    );

    synchronizer #(.WIDTH(DW/8)) synchronizer_m_pwstrb (
        .clk(M_APB_PCLK),
        .reset(M_PRESETn),
        .in(m_apb_pwstrb)
    );

    synchronizer #(.WIDTH(3)) synchronizer_m_pprot (
        .clk(M_APB_PCLK),
        .reset(M_PRESETn),
        .in(m_apb_pprot)
    );

    synchronizer #(.WIDTH(1)) synchronizer_m_pready (
        .clk(M_APB_PCLK),
        .reset(M_PRESETn),
        .in(m_apb_pready)
    );

    synchronizer #(.WIDTH(DW)) synchronizer_m_prdata (
        .clk(M_APB_PCLK),
        .reset(M_PRESETn),
        .in(m_apb_prdata)
    );

    synchronizer #(.WIDTH(1)) synchronizer_m_pslverr (
        .clk(M_APB_PCLK),
        .reset(M_PRESETn),
        .in(m_apb_pslverr)
    );

    bridge_controller bridge_controller (
        .clk_s_apb(clk_s_apb),
        .reset_s_apb(reset_s_apb),
        .s_apb_psel(s_apb_psel),
        .s_apb_penable(s_apb_penable),
        .s_apb_paddr(s_apb_paddr),
        .s_apb_pwrite(s_apb_pwrite),
        .s_apb_pwdata(s_apb_pwdata),
        .s_apb_pwstrb(s_apb_pwstrb),
        .s_apb_pprot(s_apb_pprot),
        .s_apb_pready(s_apb_pready),
        .s_apb_prdata(s_apb_prdata),
        .s_apb_pslverr(s_apb_pslverr),
        .clk_m_apb(clk_m_apb),
        .reset_m_apb(reset_m_apb),
        .m_apb_psel(m_apb_psel),
        .m_apb_penable(m_apb_penable),
        .m_apb_paddr(m_apb_paddr),
        .m_apb_pwrite(m_apb_pwrite),
        .m_apb_pwdata(m_apb_pwdata),
        .m_apb_pwstrb(m_apb_pwstrb),
        .m_apb_pprot(m_apb_pprot),
        .m_apb_pready(m_apb_pready),
        .m_apb_prdata(m_apb_prdata),
        .m_apb_pslverr(m_apb_pslverr)
    );

endmodule

module synchronizer #(
    parameter WIDTH = 1
) (
    input wire clk,
    input wire reset,
    input wire [WIDTH-1:0] in,
    output reg [WIDTH-1:0] out
);

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            out <= {WIDTH{1'b0}};
        end else begin
            out <= in;
        end
    end

endmodule

module bridge_controller (
    input wire clk_s_apb,
    input wire reset_s_apb,
    input wire s_apb_psel,
    input wire s_apb_penable,
    input wire [AW-1:0] s_apb_paddr,
    input wire s_apb_pwrite,
    input wire [DW-1:0] s_apb_pwdata,
    input wire [DW/8-1:0] s_apb_pwstrb,
    input wire [2:0] s_apb_pprot,
    output reg s_apb_pready,
    output reg [DW-1:0] s_apb_prdata,
    output reg s_apb_pslverr,
    input wire clk_m_apb,
    input wire reset_m_apb,
    output reg m_apb_psel,
    output reg m_apb_penable,
    output reg [AW-1:0] m_apb_paddr,
    output reg m_apb_pwrite,
    output reg [DW-1:0] m_apb_pwdata,
    output reg [DW/8-1:0] m_apb_pwstrb,
    output reg [2:0] m_apb_pprot,
    input wire m_apb_pready,
    input wire [DW-1:0] m_apb_prdata,
    input wire m_apb_pslverr
);

    reg [AW-1:0] m_apb_paddr_reg;
    reg m_apb_pwrite_reg;
    reg [DW-1:0] m_apb_pwdata_reg;
    reg [DW/8-1:0] m_apb_pwstrb_reg;
    reg [2:0] m_apb_pprot_reg;

    always @(posedge clk_s_apb or posedge reset_s_apb) begin
        if (reset_s_apb) begin
            s_apb_pready <= 1'b0;
            s_apb_prdata <= {DW{1'b0}};
            s_apb_pslverr <= 1'b0;
        end else if (s_apb_psel && s_apb_penable) begin
            if (!m_apb_pready) begin
                m_apb_psel <= 1'b1;
                m_apb_paddr <= s_apb_paddr;
                m_apb_pwrite <= s_apb_pwrite;
                m_apb_pwdata <= s_apb_pwdata;
                m_apb_pwstrb <= s_apb_pwstrb;
                m_apb_pprot <= s_apb_pprot;
            end else begin
                s_apb_pready <= 1'b1;
                s_apb_prdata <= m_apb_prdata;
                s_apb_pslverr <= m_apb_pslverr;
                m_apb_psel <= 1'b0;
            end
        end else begin
            s_apb_pready <= 1'b0;
            m_apb_psel <= 1'b0;
        end
    end

endmodule
