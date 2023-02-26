function power = calc_total_power(loads, machines)

    machine_names = fieldnames(machines)';
    power = 0;
    for i = 1:numel(machine_names)
        params = machines.(machine_names{i});
        power = power + sample_op_pts_poly(loads(i), params, 0);
    end

end