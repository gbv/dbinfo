requires 'perl', '5.14.1';

requires 'Plack::Middleware::Debug';
requires 'Plack::Middleware::TemplateToolkit', '0.21';
requires 'Plack::Middleware::Log::Contextual';
requires 'Plack::Middleware::XForwardedFor';
requires 'Plack::Middleware::Negotiate', '0.06';

requires 'LWP::Simple'; # ...

requires 'RDF::Flow', '>= 0.175';

requires 'Plack::Middleware::Cached';
requires 'Plack::Middleware::Rewrite';
requires 'Plack::Middleware::TemplateToolkit','0.21';

requires 'RDF::Lazy', '>= 0.081';

requires 'Template::Plugin::JSON::Escape';
requires 'Template::Plugin::Number::Format';

requires 'URI::Escape';

# requirements met by Debian packages
requires 'RDF::Trine';
requires 'RDF::NS', '20130930';
requires 'CHI';
requires 'JSON';
requires 'Log::Contextual', '0.006000';
requires 'Try::Tiny';

# test requirements
test_requires 'Plack::Util::Load';

# build requirements
build_requires 'Pandoc::Elements';
