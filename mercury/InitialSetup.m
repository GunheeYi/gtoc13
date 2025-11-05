function [data, indices, constants] = InitialSetup(mode)
    arguments
        mode (1,1) {mustBeMember(mode,["force","default"])} = "default"
    end

    % if strcmp(mode,"default") && exist("gtoc13_setup.mat","file")
    %     load("gtoc13_setup.mat","data","indices","constants")
    %     return
    % end

    data_pnt = readmatrix("gtoc13_planets.csv") ;
    data_ast = readmatrix("gtoc13_asteroids.csv") ;
    data_cmt = readmatrix("gtoc13_comets.csv") ;

    data = struct( ...
        'Type',{}, ...
        'Name',{}, ...
        'GM',{}, ...
        'Radius',{}, ...
        'K0',{}, ...
        'Weight',{}) ;

    planetNames = {
        'Vulcan'
        'Yavin'
        'Eden'
        'Hoth'
        'Yandi'
        'Beyonce'
        'Bespin'
        'Jotunn'
        'Wakonyingo'
        'Rogue1'
        'PlanetX'} ;

    indices = struct( ...
        'all',[], ...
        'Planet',[], ...
        'Asteroid',[], ...
        'Comet',[]) ;

    for idx = 1:size(data_pnt,1)
        id = data_pnt(idx,1) ;
        indices.Planet(end+1) = id ;

        data(id).Type = 'Planet' ;
        data(id).Name = planetNames{idx} ;
        data(id).GM = data_pnt(idx,3) ;
        data(id).Radius = data_pnt(idx,4) ;
        data(id).K0 = data_pnt(idx,5:10) ;
        data(id).Weight = data_pnt(idx,11) ;
    end

    for idx = 1:size(data_ast,1)
        id = data_ast(idx,1) ;
        indices.Asteroid(end+1) = id ;

        data(id).Type = 'Asteroid' ;
        data(id).GM = 0 ;
        data(id).Radius = 0 ;
        data(id).K0 = data_ast(idx,2:7) ;
        data(id).Weight = data_ast(idx,8) ;
    end

    for idx = 1:size(data_cmt,1)
        id = data_cmt(idx,1) ;
        indices.Comet(end+1) = id ;

        data(id).Type = 'Comet' ;
        data(id).GM = 0 ;
        data(id).Radius = 0 ;
        data(id).K0 = data_cmt(idx,2:7) ;
        data(id).Weight = data_cmt(idx,8) ;
    end

    indices.all = sort([indices.Planet indices.Asteroid indices.Comet]) ;

    constants = struct( ...
        'AU',149597870.691, ...
        'GM',139348062043.343, ...
        'Day',86400, ...
        'Year',365.25) ;

    % save("gtoc13_setup.mat","data","indices","constants")
end