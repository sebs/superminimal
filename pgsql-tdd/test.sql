create or replace procedure test.insert_url_scheme() language plpgsql as $$
begin
    -- arrange
    insert into test.url_schemes (scheme_name) values ('http');
    insert into test.url_schemes (scheme_name) values ('https');

    -- act & assert
    assert (select count(*) from test.url_schemes where scheme_name in ('http', 'https')) = 2,
        'Expected 2 rows for schemes http and https';

    assert (select scheme_name from test.url_schemes where scheme_name = 'http') = 'http',
        'Expected scheme_name "http" for scheme http';

    assert (select scheme_name from test.url_schemes where scheme_name = 'https') = 'https',
        'Expected scheme_name "https" for scheme https';

    rollback;
end;
$$;
call test.insert_url_scheme();