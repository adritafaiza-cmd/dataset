module apbxclk #(
  parameter C_APB_ADDR_WIDTH = 12,
  parameter C_APB_DATA_WIDTH = 32,
  parameter [0:0] OPT_REGISTERED = 1'b0
)(
  input  wire                         S_APB_PCLK,
  input  wire                         S_PRESETn,
  input  wire                         S_APB_PSEL,
  input  wire                         S_APB_PENABLE,
  output reg                          S_APB_PREADY,
  input  wire [C_APB_ADDR_WIDTH-1:0]  S_APB_PADDR,
  input  wire                         S_APB_PWRITE,
  input  wire [C_APB_DATA_WIDTH-1:0]  S_APB_PWDATA,
  input  wire [C_APB_DATA_WIDTH/8-1:0] S_APB_PWSTRB,
  input  wire [2:0]                   S_APB_PPROT,
  output wire [C_APB_DATA_WIDTH-1:0]  S_APB_PRDATA,
  output wire                         S_APB_PSLVERR,

  input  wire                         M_APB_PCLK,
  output reg                          M_PRESETn,
  output reg                          M_APB_PSEL,
  output reg                          M_APB_PENABLE,
  input  wire                         M_APB_PREADY,
  output wire [C_APB_ADDR_WIDTH-1:0]  M_APB_PADDR,
  output wire                         M_APB_PWRITE,
  output wire [C_APB_DATA_WIDTH-1:0]  M_APB_PWDATA,
  output wire [C_APB_DATA_WIDTH/8-1:0] M_APB_PWSTRB,
  output wire [2:0]                   M_APB_PPROT,
  input  wire [C_APB_DATA_WIDTH-1:0]  M_APB_PRDATA,
  input  wire                         M_APB_PSLVERR
);

// S_APB_PSEL and S_APB_PENABLE are registered
reg S_APB_PSEL_r;
reg S_APB_PENABLE_r;

// M_APB_PSEL and M_APB_PENABLE are registered
reg M_APB_PSEL_r;
reg M_APB_PENABLE_r;

// S_APB_PREADY is registered
reg S_APB_PREADY_r;

// M_APB_PREADY is registered
reg M_PRESETn_r;

// S_APB_PADDR is registered
reg [C_APB_ADDR_WIDTH-1:0] S_APB_PADDR_r;

// S_APB_PWRITE is registered
reg S_APB_PWRITE_r;

// S_APB_PWRITE is registered
reg [C_APB_DATA_WIDTH-1:0] S_APB_PWDATA_r;

// S_APB_PWSTRB is registered
reg [C_APB_DATA_WIDTH/8-1:0] S_APB_PWSTRB_r;

// S_APB_PPROT is registered
reg [2:0] S_APB_PPROT_r;

// M_APB_PADDR is registered
reg [C_APB_ADDR_WIDTH-1:0] M_APB_PADDR_r;

// M_APB_PWRITE is registered
reg M_APB_PWRITE_r;

// M_APB_PWRITE is registered
reg [C_APB_DATA_WIDTH-1:0] M_APB_PWDATA_r;

// M_APB_PWSTRB is registered
reg [C_APB_DATA_WIDTH/8-1:0] M_APB_PWSTRB_r;

  // S_APB_PRDATA is registered
  reg [C_APB_DATA_WIDTH-1:0] S_APB_PRDATA_r;
  // S_APB_PSLVERR is registered
  reg S_APB_PSLVERR_r;

  // M_APB_PRDATA is registered
  reg [C_APB_DATA_WIDTH-1:0] M_APB_PRDATA_r;
  // M_APB_PSLVERR is registered
  reg M_APB_PSLVERR_r;
  // M_PRESETn is registered
  reg M_PRESETn_r;
  // S_APB_PREADY is registered
  reg [0:0] S_APB_PREADY_r;
  reg [0:0] S_APB_PREADY_next;
  // M_APB_PREADY is registered
  reg [0:0] M_APB_PREADY_r;
  reg [0:0] M_APB_PREADY_next;
  reg [0:0] M_APB_PREADY_next_r;
  reg [0:0] M_APB_PREADY_next_r_en; 
  reg [0:0] M_APB_PREADY_next_r_en_r; 
  reg [0:0] M_APB_PREADY_next_r_en_r_en; 
  reg [0:0] M_APB_PREADY_next_r_en_r_en_r; 
  reg [0:0] M_APB_PREADY_next_r_en_d1; 
  reg [0:0] M_APB_PREADY_next_r_en_d2; 
  reg [0:0] M_APB_PREADY_next_r_en_d3; 
  reg [0:0] M_APB_PREADY_next_r_en_d4; 
  reg [0:0] M_APB_PREADY_next_r_en_d5; 
  reg [0:0] M_APB_PREADY_next_r_en_d6; 
  reg [0:0] M_APB_PREADY_next_r_en_d7; 
  reg [0:0] M_APB_PREADY_next_r_en_d8;  // 
  reg [0:0] M_APB_PREADY_d1; 
  reg [0:0] M_APB_PREADY_d2; 
  reg [0:0] M_APB_PREADY_d3; 
  reg [0:0] M_APB_PREADY_d4; 
  reg [0:0] M_APB_PREADY_d5; 
  reg [0:0] M_APB_PREADY_d6; 
 module apbxclk #(
  parameter C_APB_ADDR_WIDTH = 12,
  parameter C_APB_DATA_WIDTH = 32,
  parameter [0:0] OPT_REGISTERED = 1'b0
)(
  input  wire                         S_APB_PCLK,
  input  wire                         S_PRESETn,
  input  wire                         S_APB_PSEL,
  input  wire                         S_APB_PENABLE,
  output reg                          S_APB_PREADY,
  input  wire [C_APB_ADDR_WIDTH-1:0]  S_APB_PADDR,
  input  wire                         S_APB_PWRITE,
  input  wire [C_APB_DATA_WIDTH-1:0]  S_APB_PWDATA,
  input  wire [C_APB_DATA_WIDTH/8-1:0] S_APB_PWSTRB,
  input  wire [2:0]                   S_APB_PPROT,
  output wire [C_APB_DATA_WIDTH-1:0]  S_APB_PRDATA,
  output wire                         S_APB_PSLVERR,

  input  wire                         M_APB_PCLK,
