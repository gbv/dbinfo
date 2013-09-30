requires 'perl', '5.14.1';

requires 'Plack', '>= 1.0';
requires 'Starman', '>= 0.4008';

requires 'Plack::Middleware::Debug';
requires 'Plack::Middleware::TemplateToolkit';

requires 'RDF::NS', '20130926';

requires 'CHI';
requires 'Digest::MD5'; # core?
requires 'JSON'; # core?
requires 'Log::Contextual', '0.006000';
requires 'LWP::Simple'; # ...

#requires 'parent 'GBV::App::URI::Base';

requires 'RDF::Flow', '>= 0.175';

requires 'Plack::Middleware::Cached';
requires 'Plack::Middleware::RDF::Flow', '0.161';
requires 'Plack::Middleware::Rewrite';
requires 'Plack::Middleware::TemplateToolkit','0.21';
requires 'RDF::Dumper';

requires 'RDF::Lazy', '>= 0.061';

requires 'RDF::Trine';

#requires 'Template::Plugin::JSON::Escape;
#requires 'Template::Plugin::Number::Format;

requires 'Try::Tiny';
requires 'URI::Escape';
