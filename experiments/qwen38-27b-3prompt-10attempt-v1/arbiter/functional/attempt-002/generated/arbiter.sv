module arbiter #
(
    parameter PORTS = 4,
    parameter ARB_TYPE_ROUND_ROBIN = 0,
    parameter ARB_BLOCK = 0,
    parameter ARB_BLOCK_ACK = 1,
    parameter ARB_LSB_HIGH_PRIORITY = 0
)
(
    input  wire                     clk,
    input  wire                     rst,
    input  wire [PORTS-1:0]         request,
    input  wire [PORTS-1:0]         acknowledge,
    output wire [PORTS-1:0]         grant,
    output wire                     grant_valid,
    output wire [$clog2(PORTS)-1:0] grant_encoded
);

    localparam NUM_PORTS = PORTS;
    localparam ENC_WIDTH = $clog2(PORTS);

    // Internal signals
    wire [NUM_PORTS-1:0] grant_comb;
    wire [NUM_PORTS-1:0] grant_reg;
    wire                 grant_valid_comb;
    wire                 grant_valid_reg;
    wire [ENC_WIDTH-1:0] grant_encoded_comb;
    wire [ENC_WIDTH-1:0] grant_encoded_reg;

    // Priority pointer for round-robin
    reg [ENC_WIDTH-1:0] rr_ptr;

    // Combinational grant logic
    // Determine which port gets the grant based on request and priority scheme

    // For fixed priority:
    //   If ARB_LSB_HIGH_PRIORITY: LSB has highest priority (port 0 wins ties)
    //   Else: MSB has highest priority (port PORTS-1 wins ties)
    //
    // For round-robin:
    //   Rotate the request vector so that the current pointer position becomes the "highest" priority
    //   Then apply fixed-priority logic on the rotated vector
    //   The grant is then rotated back

    // Helper: find first set bit from LSB (lowest index)
    // This gives the lowest-index requestor
    function [NUM_PORTS-1:0] find_first_set_lsb;
        input [NUM_PORTS-1:0] vec;
        integer i;
        begin
            find_first_set_lsb = {NUM_PORTS{1'b0}};
            for (i = 0; i < NUM_PORTS; i = i + 1) begin
                if (vec[i] && find_first_set_lsb == {NUM_PORTS{1'b0}}) begin
                    find_first_set_lsb[i] = 1'b1;
                end
            end
        end
    endfunction

    // Helper: find first set bit from MSB (highest index)
    function [NUM_PORTS-1:0] find_first_set_msb;
        input [NUM_PORTS-1:0] vec;
        integer i;
        begin
            find_first_set_msb = {NUM_PORTS{1'b0}};
            for (i = NUM_PORTS-1; i >= 0; i = i - 1) begin
                if (vec[i] && find_first_set_msb == {NUM_PORTS{1'b0}}) begin
                    find_first_set_msb[i] = 1'b1;
                end
            end
        end
    endfunction

    // For round-robin, we need to rotate the request vector
    // The idea: shift the request vector left by rr_ptr positions (with wrap-around)
    // Then the "first set bit from LSB" in the rotated vector corresponds to the next requestor after rr_ptr
    // Then rotate the grant back

    wire [NUM_PORTS-1:0] request_rotated;
    wire [NUM_PORTS-1:0] grant_rotated;
    wire [NUM_PORTS-1:0] grant_rotated_back;

    // Rotate request left by rr_ptr
    // rotated[i] = request[(i - rr_ptr) mod NUM_PORTS]
    // Actually, let's think about this more carefully.
    // We want the port at position rr_ptr to have the highest priority in the rotated space.
    // If we rotate the request vector so that position rr_ptr moves to position 0,
    // then in the rotated vector, position 0 corresponds to original position rr_ptr.
    // Then we apply fixed priority (LSB or MSB) on the rotated vector.
    // The grant in rotated space is at some position j.
    // The original position is (j + rr_ptr) mod NUM_PORTS.

    // Let's define: rotated_vec[i] = request[(i + rr_ptr) % NUM_PORTS]
    // So rotated_vec[0] = request[rr_ptr], rotated_vec[1] = request[(rr_ptr+1)%NUM_PORTS], etc.
    // Then if we pick the lowest-index set bit in rotated_vec (LSB priority), that's the first requestor at or after rr_ptr.
    // If we pick the highest-index set bit in rotated_vec (MSB priority), that's the last requestor before wrapping.

    // Actually, for round-robin, the typical approach is:
    // 1. Rotate request so that the current pointer is at position 0
    // 2. Apply fixed priority (usually LSB = highest priority in rotated space)
    // 3. Rotate the grant back

    // Let's use: rotated[i] = request[(i + rr_ptr) % NUM_PORTS]
    // Then grant_rotated is the one-hot in rotated space
    // grant_original[j] = grant_rotated[(j - rr_ptr + NUM_PORTS) % NUM_PORTS]
    // i.e., grant_original = rotate_right(grant_rotated, rr_ptr)

    genvar gi;
    generate
        for (gi = 0; gi < NUM_PORTS; gi = gi + 1) begin : gen_rot
            assign request_rotated[gi] = request[(gi + rr_ptr) % NUM_PORTS];
        end
    endgenerate

    // Fixed priority selection on rotated vector
    wire [NUM_PORTS-1:0] grant_fixed_rotated;
    wire                 any_request_rotated;

    assign any_request_rotated = |request_rotated;

    // If LSB high priority: lowest index wins
    // If MSB high priority: highest index wins
    assign grant_fixed_rotated = ARB_LSB_HIGH_PRIORITY ? find_first_set_lsb(request_rotated) : find_first_set_msb(request_rotated);

    // Rotate grant back: grant_original[j] = grant_fixed_rotated[(j - rr_ptr + NUM_PORTS) % NUM_PORTS]
    generate
        for (gi = 0; gi < NUM_PORTS; gi = gi + 1) begin : gen_rot_back
            assign grant_rotated_back[gi] = grant_fixed_rotated[(gi - rr_ptr + NUM_PORTS) % NUM_PORTS];
        end
    endgenerate

    // For fixed priority (non-round-robin), just apply fixed priority directly
    wire [NUM_PORTS-1:0] grant_fixed_direct;
    assign grant_fixed_direct = ARB_LSB_HIGH_PRIORITY ? find_first_set_lsb(request) : find_first_set_msb(request);

    // Select between round-robin and fixed
    assign grant_comb = ARB_TYPE_ROUND_ROBIN ? grant_rotated_back : grant_fixed_direct;

    assign grant_valid_comb = |grant_comb;

    // Encode grant to binary
    // grant_encoded is the index of the set bit in grant_comb
    reg [ENC_WIDTH-1:0] enc_temp;
    integer ei;
    always @* begin
        enc_temp = {ENC_WIDTH{1'b0}};
        for (ei = 0; ei < NUM_PORTS; ei = ei + 1) begin
            if (grant_comb[ei]) begin
                enc_temp = ei[ENC_WIDTH-1:0];
            end
        end
    end
    assign grant_encoded_comb = enc_temp;

    // Blocking logic
    // When ARB_BLOCK is set:
    //   If ARB_BLOCK_ACK is nonzero: hold grant until acknowledge is received
    //   If ARB_BLOCK_ACK is zero: hold grant until request drops

    // We need to register the grant to hold it
    // The grant is updated when:
    //   - Not blocking: every cycle
    //   - Blocking with ACK: when acknowledge is received for the current grant
    //   - Blocking without ACK: when the request for the current grant drops

    wire block_active;
    wire block_release;

    assign block_active = ARB_BLOCK;

    // Determine when to update the grant
    // If not blocking, always update
    // If blocking:
    //   If ARB_BLOCK_ACK: release when acknowledge[grant_index] is high
    //   Else: release when request[grant_index] is low

    wire [NUM_PORTS-1:0] grant_for_check;
    assign grant_for_check = grant_reg;

    wire ack_received;
    wire req_dropped;

    assign ack_received = | (grant_for_check & acknowledge);
    assign req_dropped  = | (grant_for_check & ~request);

    // When blocking, we hold the grant until the release condition is met
    // The release condition depends on ARB_BLOCK_ACK
    wire release_condition;
    assign release_condition = ARB_BLOCK_ACK ? ack_received : req_dropped;

    // Update condition:
    // If not blocking: always update
    // If blocking: update when release_condition is true OR when there's no current grant
    wire update_grant;
    assign update_grant = block_active ? (release_condition || !grant_valid_reg) : 1'b1;

    // Register the grant
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            grant_reg <= {NUM_PORTS{1'b0}};
            grant_valid_reg <= 1'b0;
            grant_encoded_reg <= {ENC_WIDTH{1'b0}};
            rr_ptr <= {ENC_WIDTH{1'b0}};
        end else begin
            if (update_grant) begin
                grant_reg <= grant_comb;
                grant_valid_reg <= grant_valid_comb;
                grant_encoded_reg <= grant_encoded_comb;

                // Update round-robin pointer
                // The pointer should advance to the next position after the granted port
                // So that the next grant starts after the current one
                if (grant_valid_comb) begin
                    // Advance pointer to the position after the granted port
                    // If granted port is i, next pointer is (i + 1) % NUM_PORTS
                    // We need to find which port was granted
                    // grant_encoded_comb gives us the index
                    rr_ptr <= (grant_encoded_comb + 1'b1) % NUM_PORTS;
                end
            end
        end
    end

    // Output assignments
    assign grant = grant_reg;
    assign grant_valid = grant_valid_reg;
    assign grant_encoded = grant_encoded_reg;

endmodule
