module apbxclk #(
  parameter C_APB_ADDR_WIDTH = 12,
  parameter C_APB_DATA_WIDTH = 32,
  parameter [0:0] OPT_REGISTERED = 1'b0
)(
  input  wire                          S_APB_PCLK,
  input  wire                          S_PRESETn,
  input  wire                          S_APB_PSEL,
  input  wire                          S_APB_PENABLE,
  output reg                           S_APB_PREADY,
  input  wire [C_APB_ADDR_WIDTH-1:0]   S_APB_PADDR,
  input  wire                          S_APB_PWRITE,
  input  wire [C_APB_DATA_WIDTH-1:0]   S_APB_PWDATA,
  input  wire [C_APB_DATA_WIDTH/8-1:0] S_APB_PWSTRB,
  input  wire [2:0]                    S_APB_PPROT,
  output wire [C_APB_DATA_WIDTH-1:0]   S_APB_PRDATA,
  output wire                          S_APB_PSLVERR,

  input  wire                          M_APB_PCLK,
  output reg                           M_PRESETn,
  output reg                           M_APB_PSEL,
  output reg                           M_APB_PENABLE,
  input  wire                          M_APB_PREADY,
  output wire [C_APB_ADDR_WIDTH-1:0]   M_APB_PADDR,
  output wire                          M_APB_PWRITE,
  output wire [C_APB_DATA_WIDTH-1:0]   M_APB_PWDATA,
  output wire [C_APB_DATA_WIDTH/8-1:0] M_APB_PWSTRB,
  output wire [2:0]                    M_APB_PPROT,
  input  wire [C_APB_DATA_WIDTH-1:0]   M_APB_PRDATA,
  input  wire                          M_APB_PSLVERR
);

  localparam integer C_APB_STRB_WIDTH = C_APB_DATA_WIDTH / 8;

  reg m_reset_sync;

  reg req_toggle;
  reg req_busy;

  reg [C_APB_ADDR_WIDTH-1:0] req_addr;
  reg                        req_write;
  reg [C_APB_DATA_WIDTH-1:0] req_wdata;
  reg [C_APB_STRB_WIDTH-1:0] req_wstrb;
  reg [2:0]                  req_prot;

  reg ack_meta;
  reg ack_sync;

  reg [C_APB_DATA_WIDTH-1:0] s_resp_rdata;
  reg                        s_resp_slverr;

  reg req_meta;
  reg req_sync;
  reg ack_toggle;
  reg active_toggle;

  reg [C_APB_ADDR_WIDTH-1:0] m_req_addr;
  reg                        m_req_write;
  reg [C_APB_DATA_WIDTH-1:0] m_req_wdata;
  reg [C_APB_STRB_WIDTH-1:0] m_req_wstrb;
  reg [2:0]                  m_req_prot;

  reg [C_APB_DATA_WIDTH-1:0] m_resp_rdata;
  reg                        m_resp_slverr;

  reg [1:0] m_state;

  localparam [1:0] M_IDLE   = 2'b00;
  localparam [1:0] M_SETUP  = 2'b01;
  localparam [1:0] M_ACCESS = 2'b10;

  always @(posedge M_APB_PCLK or negedge S_PRESETn) begin
    if (!S_PRESETn) begin
      m_reset_sync <= 1'b0;
      M_PRESETn    <= 1'b0;
    end else begin
      m_reset_sync <= 1'b1;
      M_PRESETn    <= m_reset_sync;
    end
  end

  always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
    if (!S_PRESETn) begin
      ack_meta <= 1'b0;
      ack_sync <= 1'b0;
    end else begin
      ack_meta <= ack_toggle;
      ack_sync <= ack_meta;
    end
  end

  always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
    if (!S_PRESETn) begin
      S_APB_PREADY  <= 1'b0;
      req_toggle    <= 1'b0;
      req_busy      <= 1'b0;
      req_addr      <= {C_APB_ADDR_WIDTH{1'b0}};
      req_write     <= 1'b0;
      req_wdata     <= {C_APB_DATA_WIDTH{1'b0}};
      req_wstrb     <= {C_APB_STRB_WIDTH{1'b0}};
      req_prot      <= 3'b000;
      s_resp_rdata  <= {C_APB_DATA_WIDTH{1'b0}};
      s_resp_slverr <= 1'b0;
    end else begin
      S_APB_PREADY <= 1'b0;

      if (!req_busy) begin
        if (S_APB_PSEL && !S_APB_PENABLE) begin
          req_addr   <= S_APB_PADDR;
          req_write  <= S_APB_PWRITE;
          req_wdata  <= S_APB_PWDATA;
          req_wstrb  <= S_APB_PWSTRB;
          req_prot   <= S_APB_PPROT;
          req_toggle <= ~req_toggle;
          req_busy   <= 1'b1;
        end
      end else if (ack_sync == req_toggle) begin
        s_resp_rdata  <= m_resp_rdata;
        s_resp_slverr <= m_resp_slverr;
        S_APB_PREADY  <= 1'b1;
        req_busy      <= 1'b0;
      end
    end
  end

  always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
    if (!M_PRESETn) begin
      req_meta <= 1'b0;
      req_sync <= 1'b0;
    end else begin
      req_meta <= req_toggle;
      req_sync <= req_meta;
    end
  end

  always @(posedge M_APB_PCLK or negedge M_PRESETn) begin
    if (!M_PRESETn) begin
      M_APB_PSEL    <= 1'b0;
      M_APB_PENABLE <= 1'b0;
      ack_toggle    <= 1'b0;
      active_toggle <= 1'b0;
      m_req_addr    <= {C_APB_ADDR_WIDTH{1'b0}};
      m_req_write   <= 1'b0;
      m_req_wdata   <= {C_APB_DATA_WIDTH{1'b0}};
      m_req_wstrb   <= {C_APB_STRB_WIDTH{1'b0}};
      m_req_prot    <= 3'b000;
      m_resp_rdata  <= {C_APB_DATA_WIDTH{1'b0}};
      m_resp_slverr <= 1'b0;
      m_state       <= M_IDLE;
    end else begin
      case (m_state)
        M_IDLE: begin
          M_APB_PSEL    <= 1'b0;
          M_APB_PENABLE <= 1'b0;

          if (req_sync != ack_toggle) begin
            m_req_addr    <= req_addr;
            m_req_write   <= req_write;
            m_req_wdata   <= req_wdata;
            m_req_wstrb   <= req_wstrb;
            m_req_prot    <= req_prot;
            active_toggle <= req_sync;
            M_APB_PSEL    <= 1'b1;
            m_state       <= M_SETUP;
          end
        end

        M_SETUP: begin
          M_APB_PSEL    <= 1'b1;
          M_APB_PENABLE <= 1'b1;
          m_state       <= M_ACCESS;
        end

        M_ACCESS: begin
          M_APB_PSEL    <= 1'b1;
          M_APB_PENABLE <= 1'b1;

          if (M_APB_PREADY) begin
            m_resp_rdata  <= M_APB_PRDATA;
            m_resp_slverr <= M_APB_PSLVERR;
            ack_toggle    <= active_toggle;
            M_APB_PSEL    <= 1'b0;
            M_APB_PENABLE <= 1'b0;
            m_state       <= M_IDLE;
          end
        end

        default: begin
          M_APB_PSEL    <= 1'b0;
          M_APB_PENABLE <= 1'b0;
          m_state       <= M_IDLE;
        end
      endcase
    end
  end

  generate
    if (OPT_REGISTERED != 1'b0) begin : g_registered
      assign M_APB_PADDR  = m_req_addr;
      assign M_APB_PWRITE = m_req_write;
      assign M_APB_PWDATA = m_req_wdata;
      assign M_APB_PWSTRB = m_req_wstrb;
      assign M_APB_PPROT  = m_req_prot;

      assign S_APB_PRDATA  = s_resp_rdata;
      assign S_APB_PSLVERR = s_resp_slverr;
    end else begin : g_unregistered
      assign M_APB_PADDR  = req_addr;
      assign M_APB_PWRITE = req_write;
      assign M_APB_PWDATA = req_wdata;
      assign M_APB_PWSTRB = req_wstrb;
      assign M_APB_PPROT  = req_prot;

      assign S_APB_PRDATA  = m_resp_rdata;
      assign S_APB_PSLVERR = m_resp_slverr;
    end
  endgenerate

endmodule
