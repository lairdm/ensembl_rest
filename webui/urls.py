from django.conf.urls import patterns, url
from django.views.generic.base import RedirectView

from webui import views

urlpatterns = patterns('',
    url(r'^$', views.showapi, name='index'),
    url(r'^lookup/symbol/(?P<symbol>\w+)/(?P<species>\w+)/$', views.symbolbyname, name='symbolbyname'),
    url(r'^lookup/symbol/(?P<symbol>\w+)/$', views.symbolbyname, name='symbolbyname'),
    url(r'^xrefs/symbol/(?P<symbol>\w+)/(?P<species>\w+)/$', views.idbysymbol, name='idbysymbol'),
    url(r'^xrefs/symbol/(?P<symbol>\w+)/$', views.idbysymbol, name='idbysymbol'),
)
