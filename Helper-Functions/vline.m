function hhh=vline(x, varargin)
% function h=vline(x, linetype, label)
%
% Draws a vertical line on the current axes at the location specified by 'x'.  Optional arguments are
% 'linetype' (default is 'r:') and 'label', which applies a text label to the graph near the line.  The
% label appears in the same color as the line.
%
% The line is held on the current axes, and after plotting the line, the function returns the axes to
% its prior hold state.
%
% The HandleVisibility property of the line object is set to "off", so not only does it not appear on
% legends, but it is not findable by using findobj.  Specifying an output argument causes the function to
% return a handle to the line, so it can be manipulated or deleted.  Also, the HandleVisibility can be
% overridden by setting the root's ShowHiddenHandles property to on.
%
% h = vline(42,'g','The Answer')
%
% returns a handle to a green vertical line on the current axes at x=42, and creates a text object on
% the current axes, close to the line, which reads "The Answer".
%
% vline also supports vector inputs to draw multiple lines at once.  For example,
%
% vline([4 8 12],{'g','r','b'},{'l1','lab2','LABELC'})
%
% draws three lines with the appropriate labels and colors.
%
% By Brandon Kuczenski for Kensington Labs.
% brandon_kuczenski@kensingtonlabs.com
% 8 November 2001

inParser = inputParser;
inParser.addRequired('x');
inParser.addParameter('LineType', ':', @ischar);
inParser.addParameter('Color', 'red');
inParser.addParameter('Label', []);
inParser.addParameter('LineWidth', 1);
inParser.parse(x, varargin{:});
params = inParser.Results;

if length(x)>1  % vector input
    for ind=1:length(x)
        h(ind)=vline(x(ind), varargin{:});
    end
else
    g=ishold(gca);
    hold on
    
    y=get(gca,'ylim');
    h=plot([x x],y, params.LineType, 'Color', params.Color, 'LineWidth', params.LineWidth);
    if ~isempty(params.Label),
        xx=get(gca,'xlim');
        xrange=xx(2)-xx(1);
        xunit=(x-xx(1))/xrange;
        if xunit<0.8
            text(x+0.01*xrange,y(1)+0.1*(y(2)-y(1)),params.Label,'color',get(h,'color'))
        else
            text(x-.05*xrange,y(1)+0.1*(y(2)-y(1)),params.Label,'color',get(h,'color'))
        end
    end
    
    if g==0
        hold off
    end
    set(h,'tag','vline','handlevisibility','off')
end % else

if nargout
    hhh=h;
end
