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

  localparam [1:0] S_IDLE = 2'd0;
  localparam [1:0] S_WAIT = 2'd1;
  localparam [1:0] S_RESP = 2'd2;

  localparam [1:0] M_IDLE   = 2'd0;
  localparam [1:0] M_SETUP  = 2'd1;
  localparam [1:0] M_ACCESS = 2'd2;

  reg [1:0] s_state;
  reg [1:0] m_state;

  reg req_toggle;
  reg ack_toggle;

  reg ack_sync1;
  reg ack_sync2;
  reg req_sync1;
  reg req_sync2;
  reg req_seen;

  reg [1:0] m_reset_sync;

  reg [C_APB_ADDR_WIDTH-1:0]   s_req_addr;
  reg                          s_req_write;
  reg [C_APB_DATA_WIDTH-1:0]   s_req_wdata;
  reg [C_APB_DATA_WIDTH/8-1:0] s_req_wstrb;
  reg [2:0]                    s_req_prot;

  wire [C_APB_ADDR_WIDTH-1:0]   crossing_req_addr;
  wire                          crossing_req_write;
  wire [C_APB_DATA_WIDTH-1:0]   crossing_req_wdata;
  wire [C_APB_DATA_WIDTH/8-1:0] crossing_req_wstrb;
  wire [2:0]                    crossing_req_prot;

  reg [C_APB_ADDR_WIDTH-1:0]   m_req_addr;
  reg                          m_req_write;
  reg [C_APB_DATA_WIDTH-1:0]   m_req_wdata;
  reg [C_APB_DATA_WIDTH/8-1:0] m_req_wstrb;
  reg [2:0]                    m_req_prot;

  reg [C_APB_DATA_WIDTH-1:0] m_rsp_data;
  reg                        m_rsp_error;

  reg [C_APB_DATA_WIDTH-1:0] s_rsp_data;
  reg                        s_rsp_error;

  assign crossing_req_addr  =
      OPT_REGISTERED ? s_req_addr  : S_APB_PADDR;
  assign crossing_req_write =
      OPT_REGISTERED ? s_req_write : S_APB_PWRITE;
  assign crossing_req_wdata =
      OPT_REGISTERED ? s_req_wdata : S_APB_PWDATA;
  assign crossing_req_wstrb =
      OPT_REGISTERED ? s_req_wstrb : S_APB_PWSTRB;
  assign crossing_req_prot  =
      OPT_REGISTERED ? s_req_prot  : S_APB_PPROT;

  assign M_APB_PADDR  = m_req_addr;
  assign M_APB_PWRITE = m_req_write;
  assign M_APB_PWDATA = m_req_wdata;
  assign M_APB_PWSTRB = m_req_wstrb;
  assign M_APB_PPROT  = m_req_prot;

  assign S_APB_PRDATA  = OPT_REGISTERED ? s_rsp_data  : m_rsp_data;
  assign S_APB_PSLVERR = OPT_REGISTERED ? s_rsp_error : m_rsp_error;

  always @(posedge M_APB_PCLK or negedge S_PRESETn) begin
    if (!S_PRESETn) begin
      m_reset_sync <= 2'b00;
      M_PRESETn    <= 1'b0;
    end else begin
      m_reset_sync[0] <= 1'b1;
      m_reset_sync[1] <= m_reset_sync[0];
      M_PRESETn       <= m_reset_sync[1];
    end
  end

  always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
    if (!S_PRESETn) begin
      s_state       <= S_IDLE;
      S_APB_PREADY  <= 1'b0;
      req_toggle    <= 1'b0;
      ack_sync1     <= 1'b0;
      ack_sync2     <= 1'b0;

      s_req_addr    <= {C_APB_ADDR_WIDTH{1'b0}};
      s_req_write   <= 1'b0;
      s_req_wdata   <= {C_APB_DATA_WIDTH{1'b0}};
      s_req_wstrb   <= {(C_APB_DATA_WIDTH/8){1'b0}};
      s_req_prot    <= 3'b000;

      s_rsp_data    <= {C_APB_DATA_WIDTH{1'b0}};
      s_rsp_error   <= 1'b0;
    end else begin
      ack_sync1    <= ack_toggle;
      ack_sync2    <= ack_sync1;
      S_APB_PREADY <= 1'b0;

      case (s_state)
        S_IDLE: begin
          if (S_APB_PSEL && S_APB_PENABLE) begin
            s_req_addr  <= S_APB_PADDR;
            s_req_write <= S_APB_PWRITE;
            s_req_wdata <= S_APB_PWDATA;
            s_req_wstrb <= S_APB_PWSTRB;
            s_req_prot  <= S_APB_PPROT;
            req_toggle  <= ~req_toggle;
            s_state     <= S_WAIT;
          end
        end

        S_WAIT: begin
          if (ack_sync2 == req_toggle) begin
            s_rsp_data   <= m_rsp_data;
            s_rsp_error  <= m_rsp_error;
            S_APB_PREADY <= 1'b1;
            s_state      <= S_RESP;
          end
        end

        S_RESP: begin
          s_state <= S_IDLE;
        end

        default: begin
          s_state <= S_IDLE;
        end
      endcase
    end
  end

  always @(posedge M_APB_PCLK or negedge S_PRESETn) begin
    if (!S_PRESETn) begin
      m_state        <= M_IDLE;
      req_sync1      <= 1'b0;
      req_sync2      <= 1'b0;
      req_seen       <= 1'b0;
      ack_toggle     <= 1'b0;

      M_APB_PSEL     <= 1'b0;
      M_APB_PENABLE  <= 1'b0;

      m_req_addr     <= {C_APB_ADDR_WIDTH{1'b0}};
      m_req_write    <= 1'b0;
      m_req_wdata    <= {C_APB_DATA_WIDTH{1'b0}};
      m_req_wstrb    <= {(C_APB_DATA_WIDTH/8){1'b0}};
      m_req_prot     <= 3'b000;

      m_rsp_data     <= {C_APB_DATA_WIDTH{1'b0}};
      m_rsp_error    <= 1'b0;
    end else if (!M_PRESETn) begin
      m_state        <= M_IDLE;
      req_sync1      <= 1'b0;
      req_sync2      <= 1'b0;
      req_seen       <= 1'b0;
      ack_toggle     <= 1'b0;

      M_APB_PSEL     <= 1'b0;
      M_APB_PENABLE  <= 1'b0;

      m_req_addr     <= {C_APB_ADDR_WIDTH{1'b0}};
      m_req_write    <= 1'b0;
      m_req_wdata    <= {C_APB_DATA_WIDTH{1'b0}};
      m_req_wstrb    <= {(C_APB_DATA_WIDTH/8){1'b0}};
      m_req_prot     <= 3'b000;

      m_rsp_data     <= {C_APB_DATA_WIDTH{1'b0}};
      m_rsp_error    <= 1'b0;
    end else begin
      req_sync1 <= req_toggle;
      req_sync2 <= req_sync1;

      case (m_state)
        M_IDLE: begin
          M_APB_PSEL    <= 1'b0;
          M_APB_PENABLE <= 1'b0;

          if (req_sync2 != req_seen) begin
            m_req_addr    <= crossing_req_addr;
            m_req_write   <= crossing_req_write;
            m_req_wdata   <= crossing_req_wdata;
            m_req_wstrb   <= crossing_req_wstrb;
            m_req_prot    <= crossing_req_prot;
            req_seen      <= req_sync2;
            M_APB_PSEL    <= 1'b1;
            M_APB_PENABLE <= 1'b0;
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
            m_rsp_data     <= M_APB_PRDATA;
            m_rsp_error    <= M_APB_PSLVERR;
            ack_toggle     <= req_seen;
            M_APB_PSEL     <= 1'b0;
            M_APB_PENABLE  <= 1'b0;
            m_state        <= M_IDLE;
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

endmodule
