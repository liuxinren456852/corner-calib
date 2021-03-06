classdef CTrihedronObservation
    %CTrihedronObservation Class for storage of Camera and LRF data in a
    %frame
    %   Detailed explanation goes here
    
    properties
        % Camera properties
        cam_R_c_w   % 3(3x1) normals to World planes
        cam_A_R_c_w % 9x9 (rank 3) covariance matrix of R_c_w elements, groupable in 3x3 cell array
        cam_l       % 3(3x1) homogeneous lines in image (coincident with direction of normals to reprojection planes from camera center after normalization)
        cam_A_l     % TODO: In process in getCalibratedCornerData
        cam_reprN   % 3(3x1) vectors normal to reprojection planes from camera center
        cam_A_reprN % 9x9 (rank ?) Uncertainty matrix of correlated 3 normals
        cam_c_ray   % Direction vector pointing towards trihedron vertex
        
        % LRF properties
        LRF_v       % 3(2x1) direction of scan segments
        LRF_A_v     % 3x3 (rank 3) minimal covariance matrix of v elements (covariance of angles)
        LRF_l       % 3(3x1) homogeneous lines in scan plane
        LRF_A_l     % TODO
        LRF_q       % 3(2x1) 2D intersection points of scan lines
        LRF_A_q     % TODO
        
        % Derived properties (existence of data)
        thereis_LRF_v   % 1x3 mask: is there measured direction for LRF in plane?
        thereis_LRF_q   % 1x3 mask: is there measured intersection for LRF in plane?
        complete_LRF    % Logical: is there all information of LRF?
        
        % Control of outliers
        is_R_outlier    % 1x3 mask: is the correspondence an outlier for Rotation?
        is_t_outlier    % 1x3 mask: is the correspondence an outlier for Translation?
    end
    
    methods
        function obj = CTrihedronObservation( obj_Rtri, obj_LP2, obj_Nbp, c_ray,...
                LRF_v, LRF_A_v, LRF_l, LRF_A_l, LRF_q, LRF_A_q )

            obj.cam_R_c_w = obj_Rtri.X;
            obj.cam_A_R_c_w = obj_Rtri.A_X;
            obj.cam_l = obj_LP2.arr;
            obj.cam_A_l = obj_LP2.A_X;
            obj.cam_reprN = obj_Nbp.arr;
            obj.cam_A_reprN = obj_Nbp.A_X;
            obj.cam_c_ray = c_ray;
            
            obj.LRF_v = LRF_v;
            obj.LRF_A_v = LRF_A_v;
            obj.LRF_l = LRF_l;
            obj.LRF_A_l = LRF_A_l;
            obj.LRF_q = LRF_q;
            obj.LRF_A_q = LRF_A_q;
            
            obj.thereis_LRF_v = cellfun(@(x)~isempty(x), obj.LRF_v);
            obj.thereis_LRF_q = cellfun(@(x)~isempty(x), obj.LRF_q);
            obj.complete_LRF  = all( obj.thereis_LRF_v ) && all( obj.thereis_LRF_q );
            
            obj.is_R_outlier = false(1,3); % Initially supposed all inliers
            obj.is_t_outlier = false(1,3); % Initially supposed all inliers
            
            % TODO: Add tracking information?
        end
        
        function minimalPoseEstimation( )
            % TODO: If complete, compute T_tri_LRF and R_c_s
            % Below is old code to refactor
            [R_w_s, t_w_s] = co2LidarPose( cell2mat(q), signOfAxis );
            
            % Closed estimation of R_c_s according to current frame
            co(nobs).R_c_s = obj_Rtri.X * R_w_s;
            if ~isreal( co(nobs).R_c_s )
                warning('Complex value for R_c_s in iteration %d',nobs)
                keyboard
                co(nobs).R_c_s = [];
            end
            
            % Average of estimated rotations
            R_c_s = sum( reshape([co.R_c_s],3,3,[]), 3 );
            [U,~,V] = svd( R_c_s );
            R_c_s = U*V';
            
            % Solve t_c_s (closed solution with Lidar and Cam poses)
            % Add new complete observation
            repr_planes = [repr_planes, imgs(im_frame).L]; %#ok<AGROW>
            scan_points = [scan_points, cell2mat(scans(nframe).q)]; %#ok<AGROW>
            b = - dot( repr_planes, R_c_s(:,1:2) * scan_points, 1 )';
            A = repr_planes';
            
            t_c_s = A \ b;
        end
        
    end
    
end

