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
    /*
     * AXI Stream inputs
     */
    input  wire [S_COUNT*DATA_WIDTH-1:0]    s_axis_tdata,
    input  wire [S_COUNT*KEEP_WIDTH-1:0]    s_axis_tkeep,
    input  wire [S_COUNT-1:0]               s_axis_tvalid,
    output wire [S_COUNT-1:0]               s_axis_tready,
    input  wire [S_COUNT-1:0]               s_axis_tlast,
    input  wire [S_COUNT*S_ID_WIDTH-1:0]    s_axis_tid,
    input  wire [S_COUNT*S_DEST_WIDTH-1:0]  s_axis_tdest,
    input  wire [S_COUNT*USER_WIDTH-1:0]    s_axis_tuser,
    /*
     * AXI Stream outputs
     */
    output wire [M_COUNT*DATA_WIDTH-1:0]    m_axis_tdata,
    output wire [M_COUNT*KEEP_WIDTH-1:0]    m_axis_tkeep,
    output wire [M_COUNT-1:0]               m_axis_tvalid,
    input  wire [M_COUNT-1:0]               m_axis_tready,
    output wire [M_COUNT-1:0]               m_axis_tlast,
    output wire [M_COUNT*M_ID_WIDTH-1:0]    m_axis_tid,
    output wire [M_COUNT*M_DEST_WIDTH-1:0]  m_axis_tdest,
    output wire [M_COUNT*USER_WIDTH-1:0]    m_axis_tuser
);

    // Internal parameters for arbitration state
    localparam ARB_STATE_IDLE = 2'b00;
    localparam ARB_STATE_GRANT = 2'b01;
    localparam ARB_STATE_WAIT = 2'b10;

    // State registers for each output channel
    // We use a single clock domain for everything to ensure CDC safety.
    // State machine tracks which input is currently granted to which output.
    
    reg [M_COUNT-1:0] current_grant;
    reg [M_COUNT-1:0] next_grant;
    reg [M_COUNT-1:0] round_robin_counter;
    reg [M_COUNT-1:0] last_granted_input;
    reg [M_COUNT-1:0] last_granted_output;
    reg [M_COUNT-1:0] grant_valid; // Indicates if a grant is currently active
    reg [M_COUNT-1:0] grant_state; // 0: Idle, 1: Granting, 2: Waiting for ready
    
    // Input buffers to capture data on valid
    reg [S_COUNT-1:0] s_valid_reg;
    reg [S_COUNT-1:0] s_data_reg [DATA_WIDTH/8-1:0];
    reg [S_COUNT-1:0] s_keep_reg [DATA_WIDTH/8-1:0];
    reg [S_COUNT-1:0] s_last_reg;
    reg [S_COUNT-1:0] s_tid_reg;
    reg [S_COUNT-1:0] s_dest_reg;
    reg [S_COUNT-1:0] s_user_reg;

    // Output registers
    reg [M_COUNT-1:0] m_valid_reg;
    reg [M_COUNT-1:0] m_data_reg [DATA_WIDTH/8-1:0];
    reg [M_COUNT-1:0] m_keep_reg [DATA_WIDTH/8-1:0];
    reg [M_COUNT-1:0] m_last_reg;
    reg [M_COUNT-1:0] m_tid_reg;
    reg [M_COUNT-1:0] m_dest_reg;
    reg [M_COUNT-1:0] m_user_reg;

    // Arbitration State Machine Logic
    // Since we need to support Round Robin and LSB High Priority, 
    // and potentially multiple inputs wanting the same output,
    // we implement a simple state machine per output channel.
    
    // To simplify CDC and logic, we will use a single FSM that manages all outputs.
    // However, standard AXI switch behavior usually implies independent arbitration per output
    // or a centralized arbiter. Given the parameters, a centralized arbiter per output 
    // is the most robust approach for "Route S_COUNT inputs to M_COUNT outputs".
    
    // Let's define the arbitration logic per output channel.
    // We need to track the "next" input to grant for each output in Round Robin mode.
    
    reg [S_COUNT-1:0] rr_next_input [M_COUNT-1:0];
    reg [M_COUNT-1:0] rr_active; // Is there any input wanting this output?

    // Combinational logic for next state of arbitration
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            current_grant <= 0;
            round_robin_counter <= 0;
            last_granted_input <= 0;
            last_granted_output <= 0;
            grant_valid <= 0;
            grant_state <= ARB_STATE_IDLE;
            s_valid_reg <= 0;
            m_valid_reg <= 0;
            rr_active <= 0;
            for (integer i=0; i<M_COUNT; i++) begin
                rr_next_input[i] <= 0;
            end
        end else begin
            // 1. Update Input Registers on Valid
            for (integer i=0; i<S_COUNT; i++) begin
                if (s_axis_tvalid[i]) begin
                    s_valid_reg[i] <= 1'b1;
                    s_data_reg[0][i] <= s_axis_tdata[i*DATA_WIDTH +: DATA_WIDTH];
                    if (KEEP_ENABLE) begin
                        for (integer j=0; j<KEEP_WIDTH; j++) begin
                            s_keep_reg[j][i] <= s_axis_tkeep[i*KEEP_WIDTH + j];
                        end
                    end
                    s_last_reg[i] <= s_axis_tlast[i];
                    s_tid_reg[i] <= s_axis_tid[i*S_ID_WIDTH +: S_ID_WIDTH];
                    s_dest_reg[i] <= s_axis_tdest[i*S_DEST_WIDTH +: S_DEST_WIDTH];
                    s_user_reg[i] <= s_axis_tuser[i*USER_WIDTH +: USER_WIDTH];
                end else begin
                    s_valid_reg[i] <= 1'b0;
                end
            end

            // 2. Arbitration Logic
            // Determine which inputs are requesting which outputs
            // We need to find the set of inputs that have a specific destination
            // and are valid.
            
            // Reset grant state
            grant_valid <= 0;
            grant_state <= ARB_STATE_IDLE;
            rr_active <= 0;
            
            // Calculate which outputs are requested
            for (integer out_idx = 0; out_idx < M_COUNT; out_idx++) begin
                rr_active[out_idx] = 1'b0;
                rr_next_input[out_idx] = 0;
                
                // Find the first valid input with matching destination
                // In Round Robin, we continue from the last granted input
                // In LSB High, we start from 0
                
                integer start_idx;
                if (ARB_TYPE_ROUND_ROBIN) begin
                    start_idx = last_granted_input[out_idx];
                end else begin
                    start_idx = 0;
                end
                
                // Scan for a valid input with matching dest
                for (integer in_idx = start_idx; in_idx < S_COUNT; in_idx++) begin
                    if (s_valid_reg[in_idx] && (s_dest_reg[in_idx] == out_idx)) begin
                        rr_active[out_idx] = 1'b1;
                        rr_next_input[out_idx] = in_idx;
                        break;
                    end
                end
                
                // If no input found, wrap around for RR
                if (!rr_active[out_idx] && ARB_TYPE_ROUND_ROBIN) begin
                    for (integer in_idx = 0; in_idx < start_idx; in_idx++) begin
                        if (s_valid_reg[in_idx] && (s_dest_reg[in_idx] == out_idx)) begin
                            rr_active[out_idx] = 1'b1;
                            rr_next_input[out_idx] = in_idx;
                            break;
                        end
                    end
                end
                
                // Update last granted for next time
                if (rr_active[out_idx]) begin
                    last_granted_input[out_idx] = rr_next_input[out_idx];
                end
            end

            // 3. Grant Logic
            // If an output is requested and we are idle, grant it.
            // If we are already granting, wait for ready.
            
            for (integer out_idx = 0; out_idx < M_COUNT; out_idx++) begin
                if (rr_active[out_idx]) begin
                    if (grant_state[out_idx] == ARB_STATE_IDLE) begin
                        // Grant immediately
                        current_grant[out_idx] = rr_next_input[out_idx];
                        grant_state[out_idx] = ARB_STATE_GRANT;
                        grant_valid[out_idx] = 1'b1;
                    end else if (grant_state[out_idx] == ARB_STATE_GRANT) begin
                        // Wait for ready
                        if (m_axis_tready[out_idx]) begin
                            // Move to wait state or stay? 
                            // Usually, we stay in grant state until ready, then transfer.
                            // But to support back-to-back, we can transition to WAIT.
                            grant_state[out_idx] = ARB_STATE_WAIT;
                        end
                    end else if (grant_state[out_idx] == ARB_STATE_WAIT) begin
                        // Wait for ready
                        if (m_axis_tready[out_idx]) begin
                            grant_state[out_idx] = ARB_STATE_IDLE;
                            grant_valid[out_idx] = 1'b0;
                            // Update last granted for next round robin cycle
                            last_granted_input[out_idx] = current_grant[out_idx];
                        end
                    end
                end else begin
                    // No request, reset state
                    grant_state[out_idx] = ARB_STATE_IDLE;
                    grant_valid[out_idx] = 1'b0;
                    current_grant[out_idx] = 0;
                end
            end
        end
    end

    // Output Generation Logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            m_valid_reg <= 0;
            m_data_reg <= 0;
            m_keep_reg <= 0;
            m_last_reg <= 0;
            m_tid_reg <= 0;
            m_dest_reg <= 0;
            m_user_reg <= 0;
        end else begin
            for (integer out_idx = 0; out_idx < M_COUNT; out_idx++) begin
                if (grant_valid[out_idx]) begin
                    m_valid_reg[out_idx] <= 1'b1;
                    
                    // Data
                    m_data_reg[0][out_idx] <= s_data_reg[0][current_grant[out_idx]];
                    if (KEEP_ENABLE) begin
                        for (integer j=0; j<KEEP_WIDTH; j++) begin
                            m_keep_reg[j][out_idx] <= s_keep_reg[j][current_grant[out_idx]];
                        end
                    end
                    
                    // Last
                    m_last_reg[out_idx] <= s_last_reg[current_grant[out_idx]];
                    
                    // TID
                    if (UPDATE_TID) begin
                        m_tid_reg[out_idx] <= s_tid_reg[current_grant[out_idx]];
                    end else begin
                        m_tid_reg[out_idx] <= s_tid_reg[current_grant[out_idx]]; // Pass through
                    end
                    
                    // Dest
                    m_dest_reg[out_idx] <= s_dest_reg[current_grant[out_idx]];
                    
                    // User
                    m_user_reg[out_idx] <= s_user_reg[current_grant[out_idx]];
                end else begin
                    m_valid_reg[out_idx] <= 1'b0;
                    m_data_reg[0][out_idx] <= 0;
                    if (KEEP_ENABLE) begin
                        for (integer j=0; j<KEEP_WIDTH; j++) begin
                            m_keep_reg[j][out_idx] <= 0;
                        end
                    end
                    m_last_reg[out_idx] <= 0;
                    m_tid_reg[out_idx] <= 0;
                    m_dest_reg[out_idx] <= 0;
                    m_user_reg[out_idx] <= 0;
                end
            end
        end
    end

    // Output Port Assignments
    assign m_axis_tdata = {M_COUNT{1'b0}}; // Placeholder, will be packed
    assign m_axis_tkeep = {M_COUNT{1'b0}};
    assign m_axis_tvalid = m_valid_reg;
    assign m_axis_tlast = m_last_reg;
    assign m_axis_tid = m_tid_reg;
    assign m_axis_tdest = m_dest_reg;
    assign m_axis_tuser = m_user_reg;

    // Pack outputs
    genvar i, j;
    generate
        for (i = 0; i < M_COUNT; i++) begin : m_pack_data
            for (j = 0; j < DATA_WIDTH/8; j++) begin : m_pack_keep
                assign m_axis_tdata[i*DATA_WIDTH +: DATA_WIDTH] = m_data_reg[j][i];
                assign m_axis_tkeep[i*KEEP_WIDTH + j] = m_keep_reg[j][i];
            end
        end
    endgenerate

    // Input Port Assignments (Ready)
    // s_axis_tready[i] is high if the corresponding output channel is ready
    // AND the input i is currently granted.
    // Actually, s_axis_tready[i] should be high if the switch is ready to accept data from input i.
    // This happens if:
    // 1. There is a valid grant for an output that matches input i's destination.
    // 2. The grant is currently active (grant_valid) OR the input is not yet granted but the arbiter is idle?
    // No, standard AXI: ready is asserted when the switch can accept a beat.
    // If input i is granted to output k, and output k is ready, then input i is ready.
    
    always @(*) begin
        for (integer i = 0; i < S_COUNT; i++) begin
            s_axis_tready[i] = 1'b0;
            for (integer out_idx = 0; out_idx < M_COUNT; out_idx++) begin
                if (s_dest_reg[i] == out_idx && grant_valid[out_idx]) begin
                    s_axis_tready[i] = m_axis_tready[out_idx];
                end
            end
        end
    end

endmodule
```<|im_end|>
