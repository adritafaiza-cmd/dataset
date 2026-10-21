```verilog
`timescale 1ns/1ps

module axis_switch #
(
    parameter S_COUNT = 4,
    parameter M_COUNT = 4,
    parameter DATA_WIDTH = 8,
    parameter KEEP_ENABLE = (DATA_WIDTH>8),
    parameter KEEP_WIDTH = ((DATA_WIDTH+7)/8),
    parameter ID_ENABLE = 0,
    parameter S_ID_WIDTH = 8,
    parameter M_ID_WIDTH = S_ID_WIDTH+$clog2(S_COUNT),
    parameter M_DEST_WIDTH = 1,
    parameter S_DEST_WIDTH = M_DEST_WIDTH+$clog2(M_COUNT),
    parameter USER_ENABLE = 1,
    parameter USER_WIDTH = 1,
    parameter M_BASE = 0,
    parameter M_TOP = 0,
    parameter M_CONNECT = {M_COUNT{{S_COUNT{1'b1}}}},
    parameter UPDATE_TID = 0,
    parameter S_REG_TYPE = 0,
    parameter M_REG_TYPE = 2,
    parameter ARB_TYPE_ROUND_ROBIN = 1,
    parameter ARB_LSB_HIGH_PRIORITY = 1
)
(
    input  wire                             clk,
    input  wire                             rst,
    input  wire [S_COUNT*DATA_WIDTH-1:0]    s_axis_tdata,
    input  wire [S_COUNT*KEEP_WIDTH-1:0]    s_axis_tkeep,
    input  wire [S_COUNT-1:0]               s_axis_tvalid,
    output wire [S_COUNT-1:0]               s_axis_tready,
    input  wire [S_COUNT-1:0]               s_axis_tlast,
    input  wire [S_COUNT*S_ID_WIDTH-1:0]    s_axis_tid,
    input  wire [S_COUNT*S_DEST_WIDTH-1:0]  s_axis_tdest,
    input  wire [S_COUNT*USER_WIDTH-1:0]    s_axis_tuser,
    output wire [M_COUNT*DATA_WIDTH-1:0]    m_axis_tdata,
    output wire [M_COUNT*KEEP_WIDTH-1:0]    m_axis_tkeep,
    output wire [M_COUNT-1:0]               m_axis_tvalid,
    input  wire [M_COUNT-1:0]               m_axis_tready,
    output wire [M_COUNT-1:0]               m_axis_tlast,
    output wire [M_COUNT*M_ID_WIDTH-1:0]    m_axis_tid,
    output wire [M_COUNT*M_DEST_WIDTH-1:0]  m_axis_tdest,
    output wire [M_COUNT*USER_WIDTH-1:0]    m_axis_tuser
);

    localparam LOG_S_COUNT = $clog2(S_COUNT);
    localparam LOG_M_COUNT = $clog2(M_COUNT);

    // State for Round Robin Arbitration
    reg [LOG_S_COUNT-1:0] arb_rr_index;
    reg [LOG_S_COUNT-1:0] arb_rr_mask; // Mask of available inputs for RR
    reg [LOG_S_COUNT-1:0] arb_rr_next; // Next index to try

    // Internal signals for selected input
    wire [S_COUNT-1:0] sel_idx;
    wire [DATA_WIDTH-1:0] sel_tdata;
    wire [KEEP_WIDTH-1:0] sel_tkeep;
    wire sel_tvalid;
    wire sel_tlast;
    wire [S_ID_WIDTH-1:0] sel_tid;
    wire [S_DEST_WIDTH-1:0] sel_tdest;
    wire [USER_WIDTH-1:0] sel_tuser;
    wire sel_tready;

    // Output registers
    reg [M_COUNT-1:0] m_axis_tvalid_reg;
    reg [M_COUNT-1:0] m_axis_tlast_reg;
    reg [M_COUNT-1:0] m_axis_tid_reg;
    reg [M_COUNT-1:0] m_axis_tdest_reg;
    reg [M_COUNT-1:0] m_axis_tuser_reg;
    reg [M_COUNT-1:0] m_axis_tdata_reg;
    reg [M_COUNT-1:0] m_axis_tkeep_reg;
    reg [M_COUNT-1:0] m_axis_tready_reg;

    // Ready signals from outputs to inputs
    wire [S_COUNT-1:0] out_ready;

    // Generate output ready signals based on M_CONNECT
    // If M_CONNECT[i][j] is 1, then output j is connected to input i
    genvar i, j;
    generate
        for (i = 0; i < M_COUNT; i = i + 1) begin : gen_out_ready
            for (j = 0; j < S_COUNT; j = j + 1) begin : gen_out_ready_inner
                if (M_CONNECT[i][j]) begin
                    assign out_ready[j] = m_axis_tready[i];
                end else begin
                    assign out_ready[j] = 1'b1;
                end
            end
        end
    endgenerate

    // Arbitration Logic
    // Determine which input to select based on policy
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            arb_rr_index <= 0;
            arb_rr_mask <= {S_COUNT{1'b1}};
            arb_rr_next <= 0;
        end else begin
            // Update mask: inputs that are valid and have ready from output
            arb_rr_mask <= s_axis_tvalid & out_ready;
            
            // Calculate next index for Round Robin
            if (ARB_TYPE_ROUND_ROBIN) begin
                // Find first set bit in mask
                arb_rr_next <= 0;
                for (j = 0; j < S_COUNT; j = j + 1) begin
                    if (arb_rr_mask[j]) begin
                        arb_rr_next <= j;
                        break;
                    end
                end
                
                // If no valid input, keep current index (or reset if all invalid)
                if (arb_rr_next == 0 && arb_rr_mask == 0) begin
                    arb_rr_next <= 0;
                end
            end else begin
                // Static Priority (LSB High if ARB_LSB_HIGH_PRIORITY)
                if (ARB_LSB_HIGH_PRIORITY) begin
                    arb_rr_next <= 0;
                end else begin
                    arb_rr_next <= S_COUNT - 1;
                end
            end

            // Select the input with highest priority among valid ones
            sel_idx <= 0;
            for (j = 0; j < S_COUNT; j = j + 1) begin
                if (s_axis_tvalid[j] && out_ready[j]) begin
                    if (ARB_TYPE_ROUND_ROBIN) begin
                        if (j == arb_rr_next) begin
                            sel_idx <= j;
                            break;
                        end
                    end else begin
                        // Static priority: check from high to low or low to high
                        if (ARB_LSB_HIGH_PRIORITY) begin
                            if (j < sel_idx) begin
                                sel_idx <= j;
                            end
                        end else begin
                            if (j > sel_idx) begin
                                sel_idx <= j;
                            end
                        end
                    end
                end
            end
        end
    end

    // Select data from inputs
    assign sel_tdata = s_axis_tdata[sel_idx * DATA_WIDTH +: DATA_WIDTH];
    assign sel_tkeep = s_axis_tkeep[sel_idx * KEEP_WIDTH +: KEEP_WIDTH];
    assign sel_tvalid = s_axis_tvalid[sel_idx];
    assign sel_tlast = s_axis_tlast[sel_idx];
    assign sel_tid = s_axis_tid[sel_idx * S_ID_WIDTH +: S_ID_WIDTH];
    assign sel_tdest = s_axis_tdest[sel_idx * S_DEST_WIDTH +: S_DEST_WIDTH];
    assign sel_tuser = s_axis_tuser[sel_idx * USER_WIDTH +: USER_WIDTH];
    assign sel_tready = out_ready[sel_idx];

    // Output Logic
    // Determine which output to drive
    wire [M_COUNT-1:0] drive_valid;
    wire [M_COUNT-1:0] drive_tlast;
    wire [M_COUNT-1:0] drive_tid;
    wire [M_COUNT-1:0] drive_tdest;
    wire [M_COUNT-1:0] drive_tuser;
    wire [M_COUNT-1:0] drive_tdata;
    wire [M_COUNT-1:0] drive_tkeep;

    generate
        for (i = 0; i < M_COUNT; i = i + 1) begin : gen_drive
            wire connected = M_CONNECT[i][sel_idx];
            
            assign drive_valid[i] = connected ? sel_tvalid : 1'b0;
            assign drive_tlast[i] = connected ? sel_tlast : 1'b0;
            assign drive_tid[i] = connected ? sel_tid : 0;
            assign drive_tdest[i] = connected ? sel_tdest : 0;
            assign drive_tuser[i] = connected ? sel_tuser : 0;
            assign drive_tdata[i] = connected ? sel_tdata : 0;
            assign drive_tkeep[i] = connected ? sel_tkeep : 0;
        end
    endgenerate

    // Register outputs
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            m_axis_tvalid_reg <= {M_COUNT{1'b0}};
            m_axis_tlast_reg <= {M_COUNT{1'b0}};
            m_axis_tid_reg <= {M_COUNT{M_ID_WIDTH{1'b0}}};
            m_axis_tdest_reg <= {M_COUNT{S_DEST_WIDTH{1'b0}}};
            m_axis_tuser_reg <= {M_COUNT{USER_WIDTH{1'b0}}};
            m_axis_tdata_reg <= {M_COUNT{DATA_WIDTH{1'b0}}};
            m_axis_tkeep_reg <= {M_COUNT{KEEP_WIDTH{1'b0}}};
            m_axis_tready_reg <= {M_COUNT{1'b0}};
        end else begin
            m_axis_tvalid_reg <= drive_valid;
            m_axis_tlast_reg <= drive_tlast;
            m_axis_tid_reg <= drive_tid;
            m_axis_tdest_reg <= drive_tdest;
            m_axis_tuser_reg <= drive_tuser;
            m_axis_tdata_reg <= drive_tdata;
            m_axis_tkeep_reg <= drive_tkeep;
            m_axis_tready_reg <= drive_tready;
        end
    end

    // Assign output ports
    assign m_axis_tvalid = m_axis_tvalid_reg;
    assign m_axis_tlast = m_axis_tlast_reg;
    assign m_axis_tid = m_axis_tid_reg;
    assign m_axis_tdest = m_axis_tdest_reg;
    assign m_axis_tuser = m_axis_tuser_reg;
    assign m_axis_tdata = m_axis_tdata_reg;
    assign m_axis_tkeep = m_axis_tkeep_reg;
    assign m_axis_tready = m_axis_tready_reg;

    // Assign input ready ports
    assign s_axis_tready = out_ready;

endmodule
```<|im_end|>
