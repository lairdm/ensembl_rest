from django.conf.urls import patterns, url
from django.views.generic.base import RedirectView

from webui import views

urlpatterns = patterns('',
    url(r'^$', views.showapi, name='index'),
    url(r'^xrefs/name/(?P<symbol>\w+)/(?P<species>\w+)/$', views.symbolbyname, name='symbolbyname'),
    url(r'^xrefs/name/(?P<symbol>\w+)/$', views.symbolbyname, name='symbolbyname'),
    url(r'^xrefs/symbol/(?P<symbol>\w+)/(?P<species>\w+)/$', views.idbysymbol, name='idbysymbol'),
    url(r'^xrefs/symbol/(?P<symbol>\w+)/$', views.idbysymbol, name='idbysymbol'),
    url(r'^lookup/id/(?P<id>\w+)/$', views.moleculebyid, name='moledulebyid'),
)
