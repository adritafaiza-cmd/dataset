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

    localparam W = $clog2(PORTS);

    reg [W-1:0] rr_ptr;
    reg [PORTS-1:0] grant_reg;
    reg grant_valid_reg;

    wire [PORTS-1:0] grant_comb;
    wire grant_valid_comb;
    wire [W-1:0] grant_encoded_comb;

    // Fixed priority arbiter
    // If ARB_LSB_HIGH_PRIORITY is 1, LSB has highest priority
    // If ARB_LSB_HIGH_PRIORITY is 0, MSB has highest priority (standard)
    
    // For fixed priority:
    // We need to find the highest priority requestor.
    // If ARB_LSB_HIGH_PRIORITY=1, port 0 is highest, port PORTS-1 is lowest.
    // If ARB_LSB_HIGH_PRIORITY=0, port PORTS-1 is highest, port 0 is lowest.
    
    // Let's create a priority encoder.
    // For LSB high priority: find the lowest set bit.
    // For MSB high priority: find the highest set bit.
    
    // We'll use a combinational block to compute the grant.
    
    // Helper: find lowest set bit (LSB priority)
    // Helper: find highest set bit (MSB priority)
    
    // For round robin, we rotate the request vector based on rr_ptr.
    
    // Let's define the priority order.
    // We'll create a function to get the grant based on priority order.
    
    // For simplicity, let's implement both fixed priority modes and round robin.
    
    // Fixed priority LSB high: grant = request & (~request + 1) -- lowest set bit
    // Fixed priority MSB high: need to find highest set bit
    
    // Let's use a priority encoder approach.
    
    // For LSB high priority:
    //   grant[i] = request[i] & ~(request[i-1:0] | 0) -- but this is tricky in Verilog
    //   Actually, lowest set bit: grant = request & (~request + 1)
    
    // For MSB high priority:
    //   We need to find the highest index i where request[i] is 1.
    
    // Let's implement a priority encoder for MSB high priority.
    
    // For round robin:
    //   We rotate the request vector so that the port after rr_ptr has highest priority.
    //   Then apply fixed priority (MSB high or LSB high depending on ARB_LSB_HIGH_PRIORITY).
    
    // Let's define the rotated request.
    
    // For round robin with MSB high priority (ARB_LSB_HIGH_PRIORITY=0):
    //   The port immediately after rr_ptr (wrapping) should have highest priority.
    //   So we rotate request left by rr_ptr, then find MSB high priority.
    //   The grant index in the rotated space maps back to original.
    
    // For round robin with LSB high priority (ARB_LSB_HIGH_PRIORITY=1):
    //   The port immediately after rr_ptr should have highest priority.
    //   So we rotate request left by rr_ptr, then find LSB high priority.
    
    // Let's implement this.
    
    // Rotated request: rot_req[i] = request[(i + rr_ptr) % PORTS]
    // But in Verilog, we can use concatenation and shifting.
    
    // Actually, let's think about it differently.
    // For round robin, we want to give priority to the port after the last granted port.
    // rr_ptr points to the last granted port.
    // So the next port to be granted should be (rr_ptr + 1) % PORTS.
    
    // Let's define the priority order for round robin:
    //   Priority order: (rr_ptr+1)%PORTS, (rr_ptr+2)%PORTS, ..., rr_ptr
    //   This is a rotation of the request vector.
    
    // For MSB high priority in the rotated space:
    //   We rotate request left by (rr_ptr+1), so that the highest priority port is at the MSB.
    //   Wait, let's think carefully.
    
    // Let's use a simpler approach:
    //   Create a rotated request vector where the port with highest priority is at position PORTS-1 (for MSB high) or position 0 (for LSB high).
    
    // For MSB high priority round robin:
    //   We want port (rr_ptr+1)%PORTS to have highest priority.
    //   So we rotate request left by (rr_ptr+1), and then the MSB of the rotated vector corresponds to port (rr_ptr+1)%PORTS.
    //   Wait, if we rotate left by k, then rot[i] = request[(i+k)%PORTS].
    //   So rot[PORTS-1] = request[(PORTS-1+k)%PORTS] = request[(k-1)%PORTS].
    //   That's not what we want.
    
    // Let's try: rot[i] = request[(i - k + PORTS)%PORTS] where k = rr_ptr+1.
    //   Then rot[PORTS-1] = request[(PORTS-1 - k + PORTS)%PORTS] = request[(PORTS-1 - (rr_ptr+1) + PORTS)%PORTS] = request[(2*PORTS - 2 - rr_ptr)%PORTS] = request[(PORTS - 2 - rr_ptr)%PORTS].
    //   That's still not right.
    
    // Let's just use a different approach. We'll create a priority vector.
    
    // Actually, let's use a standard round robin arbiter approach:
    //   1. Mask out requests at or below rr_ptr (for MSB high priority).
    //   2. If any masked request exists, grant the highest priority among them.
    //   3. Otherwise, grant the highest priority among all requests.
    
    // For MSB high priority:
    //   masked_req = request & ~(rr_ptr_mask) where rr_ptr_mask has 1s from 0 to rr_ptr.
    //   If masked_req != 0, grant = highest set bit of masked_req.
    //   Else, grant = highest set bit of request.
    
    // For LSB high priority:
    //   masked_req = request & ~(rr_ptr_mask) where rr_ptr_mask has 1s from rr_ptr to PORTS-1.
    //   If masked_req != 0, grant = lowest set bit of masked_req.
    //   Else, grant = lowest set bit of request.
    
    // Let's implement this.
    
    // First, let's create the mask.
    
    // For MSB high priority:
    //   mask[i] = (i <= rr_ptr) ? 1 : 0
    //   masked_req = request & ~mask
    
    // For LSB high priority:
    //   mask[i] = (i >= rr_ptr) ? 1 : 0
    //   masked_req = request & ~mask
    
    // Let's implement the priority encoders.
    
    // MSB high priority encoder:
    //   Find the highest index i where input[i] is 1.
    
    // LSB high priority encoder:
    //   Find the lowest index i where input[i] is 1.
    
    // Let's implement these as combinational logic.
    
    // For MSB high priority:
    //   We can use a tree of ORs and multiplexers.
    
    // For LSB high priority:
    //   We can use the trick: lowest_set_bit = input & (~input + 1)
    
    // Let's implement the MSB high priority encoder.
    
    // For a vector of width PORTS, the MSB high priority encoder can be implemented as:
    //   result = 0
    //   for i from PORTS-1 down to 0:
    //       if input[i]: result = i; break
    
    // In Verilog, we can use a case statement or a series of if-else.
    
    // Let's use a function.
    
    function [W-1:0] msb_high_priority;
        input [PORTS-1:0] vec;
        integer i;
        begin
            msb_high_priority = 0;
            for (i = PORTS-1; i >= 0; i = i - 1) begin
                if (vec[i]) begin
                    msb_high_priority = i[W-1:0];
                    disable msb_high_priority;
                end
            end
        end
    endfunction
    
    function [W-1:0] lsb_high_priority;
        input [PORTS-1:0] vec;
        integer i;
        begin
            lsb_high_priority = 0;
            for (i = 0; i < PORTS; i = i + 1) begin
                if (vec[i]) begin
                    lsb_high_priority = i[W-1:0];
                    disable lsb_high_priority;
                end
            end
        end
    endfunction
    
    // Now let's compute the grant.
    
    // For fixed priority:
    //   If ARB_LSB_HIGH_PRIORITY: grant = lsb_high_priority(request)
    //   Else: grant = msb_high_priority(request)
    
    // For round robin:
    //   If ARB_LSB_HIGH_PRIORITY:
    //       mask[i] = (i >= rr_ptr) ? 1 : 0
    //       masked_req = request & ~mask
    //       If masked_req != 0: grant = lsb_high_priority(masked_req)
    //       Else: grant = lsb_high_priority(request)
    //   Else:
    //       mask[i] = (i <= rr_ptr) ? 1 : 0
    //       masked_req = request & ~mask
    //       If masked_req != 0: grant = msb_high_priority(masked_req)
    //       Else: grant = msb_high_priority(request)
    
    // Let's compute the mask.
    
    reg [PORTS-1:0] mask;
    integer i;
    
    always @* begin
        for (i = 0; i < PORTS; i = i + 1) begin
            if (ARB_LSB_HIGH_PRIORITY) begin
                mask[i] = (i >= rr_ptr) ? 1'b1 : 1'b0;
            end else begin
                mask[i] = (i <= rr_ptr) ? 1'b1 : 1'b0;
            end
        end
    end
    
    wire [PORTS-1:0] masked_req = request & ~mask;
    
    // Compute the grant index.
    reg [W-1:0] grant_idx;
    
    always @* begin
        if (ARB_TYPE_ROUND_ROBIN) begin
            if (ARB_LSB_HIGH_PRIORITY) begin
                if (masked_req != 0) begin
                    grant_idx = lsb_high_priority(masked_req);
                end else begin
                    grant_idx = lsb_high_priority(request);
                end
            end else begin
                if (masked_req != 0) begin
                    grant_idx = msb_high_priority(masked_req);
                end else begin
                    grant_idx = msb_high_priority(request);
                end
            end
        end else begin
            if (ARB_LSB_HIGH_PRIORITY) begin
                grant_idx = lsb_high_priority(request);
            end else begin
                grant_idx = msb_high_priority(request);
            end
        end
    end
    
    // Create the one-hot grant vector.
    reg [PORTS-1:0] grant_onehot;
    
    always @* begin
        grant_onehot = 0;
        if (request != 0) begin
            grant_onehot[grant_idx] = 1'b1;
        end
    end
    
    // Now handle the blocking logic.
    // If ARB_BLOCK is set, hold the grant until acknowledge or request drops.
    
    // Let's compute the combinational grant.
    assign grant_comb = grant_onehot;
    assign grant_valid_comb = (request != 0);
    assign grant_encoded_comb = grant_idx;
    
    // Now the sequential logic for blocking.
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            grant_reg <= 0;
            grant_valid_reg <= 0;
            rr_ptr <= 0;
        end else begin
            if (ARB_BLOCK) begin
                if (grant_valid_reg) begin
                    // Currently holding a grant.
                    if (ARB_BLOCK_ACK) begin
                        // Hold until acknowledge.
                        if (acknowledge[grant_encoded_comb] || !grant_valid_comb) begin
                            // Acknowledge received or request dropped.
                            grant_reg <= grant_comb;
                            grant_valid_reg <= grant_valid_comb;
                            if (grant_valid_comb) begin
                                rr_ptr <= grant_encoded_comb;
                            end
                        end else begin
                            // Hold the current grant.
                            grant_reg <= grant_reg;
                            grant_valid_reg <= 1'b1;
                        end
                    end else begin
                        // Hold until request drops.
                        if (!grant_valid_comb) begin
                            grant_reg <= grant_comb;
                            grant_valid_reg <= grant_valid_comb;
                            if (grant_valid_comb) begin
                                rr_ptr <= grant_encoded_comb;
                            end
                        end else begin
                            grant_reg <= grant_reg;
                            grant_valid_reg <= 1'b1;
                        end
                    end
                end else begin
                    // No current grant.
                    grant_reg <= grant_comb;
                    grant_valid_reg <= grant_valid_comb;
                    if (grant_valid_comb) begin
                        rr_ptr <= grant_encoded_comb;
                    end
                end
            end else begin
                // No blocking.
                grant_reg <= grant_comb;
                grant_valid_reg <= grant_valid_comb;
                if (grant_valid_comb) begin
                    rr_ptr <= grant_encoded_comb;
                end
            end
        end
    end
    
    assign grant = grant_reg;
    assign grant_valid = grant_valid_reg;
    assign grant_encoded = grant_encoded_comb;

endmodule
